// The goal here is to create 7 day columns, splitting multiday events as needed,
// while finding out the earliest and latest event time in the set and preparing
// positioning data for overlapping events.

goog.require('goog.date');
goog.require('goog.i18n.DateTimeFormat');

jQuery.easing.def = "easeInOutQuad";

// What class to use for each standard iCal color.
var colorMap = {
    "blue":	        0x3C63DB,
    "blue":         0x0252D4,
    "green":	    0x42B114,
    "green":        0x2CA10B,
    "red":		    0xE12526,
    "orange":	    0xEE8C17,
    "pink":	        0xBB33BB,
    "pink":         0xB027AE,
    "turquoise":	0x6237B0   // purple in iCal
};

function colorComponents(color)
{
    return [(color & 0xFF0000) >> 16, (color & 0x00FF00) >> 8, (color & 0x0000FF)];
}

function mapColorToClass(color)
{
    var bestMatch = '',
        distance = 0xFFFFFF,
        c1 = colorComponents(color);

    //console.log("matching " + color.toString(16) + "(" + c1 + ")");
    for (var key in colorMap)
    {
        var value = colorMap[key];

        c2 = colorComponents(value);
        d = Math.sqrt(Math.pow(c1[0] - c2[0], 2) + Math.pow(c1[1] - c2[1], 2) + Math.pow(c1[2] - c2[2], 2));

        if (d < distance)
        {
            //console.log("key: " + key + "value: " + value.toString(16) + " d: " + d);
            bestMatch = key;
            distance = d;
        }
    }

    return bestMatch;
}

function createEventElement(theEvent)
{
    // <div><div class='event-mask'><span class="event green">Meet Julius Caesar for wine and grapes.</span></div></div>
    var outterWrapper = $("<div></div>"),
        eventMask = $("<div class='event-mask'></div>"),
        innerSpan = $("<span class='event'></span>"),
        titleSpan = $("<span class='title'></span>"),
        locationSpan = $("<span class='location'></span>");

    innerSpan.addClass(theEvent['colorClass']);

    titleSpan.text(theEvent['title']);
    innerSpan.append(titleSpan);

    if (theEvent['location'])
    {
        locationSpan.text(theEvent['location']);
        innerSpan.append(locationSpan);
    }

    return outterWrapper.append(eventMask.append(innerSpan));
}

function fillInTimeline(timelineElement, earliestHour, latestHour, pixelsPerHour, json)
{
    timelineElement.html('');
    for (var hour = earliestHour; hour <= latestHour; hour++)
    {
        var element = $('<span></span>'),
            hourName = json['hourNames'][hour];

        // If there's an am/pm marker, drop the :XX minute bit to make it smaller.
        if (hourName.toUpperCase().indexOf('AM') > 0 || hourName.toUpperCase().indexOf('PM') > 0)
            hourName = hourName.replace(/:(\d)+/, '');

        element.text(hourName);
        element.height(Math.floor(pixelsPerHour));
        element.css('top', Math.floor((hour - earliestHour) * pixelsPerHour));
        timelineElement.append(element);
    }
}

var MINIMUM_EVENT_HEIGHT = 28,
    FAST_FORWARD_NEXT_UP = false,

    lastUpdateDate = null,
    nextUpTimer = null;

function update(json)
{
    if (typeof(json) == 'string')
        json = $.parseJSON(json);
    console.log(json);

    lastUpdateDate = new goog.date.DateTime();
    FAST_FORWARD_NEXT_UP = json.fastForwardNextUp;

    var startDate       = goog.date.fromIsoString(json.beginningDate),
        endDate         = goog.date.fromIsoString(json.endDate),
        today           = goog.date.fromIsoString(json.date),
        earliestHour    = 9,
        latestHour      = 17,
        days            = [];

    $(".info .date .date-date").text(today.getDate());
    $(".info .date .date-month-year").text(new goog.i18n.DateTimeFormat("MMMM, y").format(today));
    $(".info .date .date-day").text(new goog.i18n.DateTimeFormat("EEEE").format(today));

    var tasksElement = $("#to-do-box .tasks");
    tasksElement.html("");
    for (var i = 0, count = json.tasks.length; i < count; i++)
    {
        var task = json.tasks[i];
        tasksElement.append($("<li></li>").text(task.title));
    }

    for (var dayIndex = 0; dayIndex < 7; dayIndex++)
    {
        var columnDate = startDate.clone(),
            column = {};

        columnDate.add(new goog.date.Interval(goog.date.Interval.DAYS, dayIndex));

        column['title'] = json.dayNames[dayIndex];

        column['allday'] = [];
        column['events'] = [];

        var columnStartDate = columnDate.clone(),
            columnEndDate = columnDate.clone();

        columnStartDate.setHours(0);
        columnStartDate.setMinutes(0);
        columnStartDate.setSeconds(0);

        columnEndDate.setHours(23);
        columnEndDate.setMinutes(59);
        columnEndDate.setSeconds(59);

        column['startDate'] = columnStartDate;

        // Go through all events, splitting and adding them into the day columns.
        // It'd probably be more efficient to only go through the list of events once,
        // but it doesn't matter.
        for (var i = 0, count = json.events.length; i < count; i++)
        {
            var theEvent = json.events[i],
                eventStart = goog.date.fromIsoString(theEvent.startDate),
                eventEnd = goog.date.fromIsoString(theEvent.endDate);

            // <= for event end - don't want events which end on midnight to show up the
            // next day.
            if (eventStart > columnEndDate || eventEnd <= columnStartDate)
                continue;

            if (!theEvent.isAllDay)
            {
                // Get only the part we want.
                if (eventStart < columnStartDate)
                    eventStart = columnStartDate;
                if (eventEnd > columnEndDate)
                    eventEnd = columnEndDate;

                if (eventStart.getHours() < earliestHour)
                    earliestHour = eventStart.getHours();
                if (eventEnd.getHours() > latestHour)
                    latestHour = eventEnd.getHours();
            }

            var formattedEvent = {};

            // Copy the event in case it goes into multiple day slots. Take this chance
            // to massage the data slightly.
            formattedEvent['title'] = theEvent.title;
            formattedEvent['location'] = theEvent.location;
            formattedEvent['startDate'] = eventStart;
            formattedEvent['endDate'] = eventEnd;
            formattedEvent['isAllDay'] = theEvent.isAllDay;
            formattedEvent['colorClass'] = mapColorToClass(parseInt(theEvent.calendar.color, 16));

            formattedEvent['compression'] = 0;
            formattedEvent['z_index'] = 0;

            if (formattedEvent['isAllDay'])
                column['allday'].push(formattedEvent);
            else
                column['events'].push(formattedEvent);
        }

        // Order events by start time.
        column['events'].sort(function(a, b)
        {
            return (a.startDate > b.startDate) - (a.startDate < b.startDate);
        });

        // Now that we have all the events split and sorted, find side by side events.
        var stack = [];
        for (var i = 0, count = column['events'].length; i < count; i++)
        {
            var theEvent = column['events'][i];

            for (var j = 0; j < stack.length; j++)
            {
                if (stack[j].endDate <= theEvent.startDate)
                {
                    // Collapse down when the root of a stack is over.
                    stack = stack.slice(0, j);
                    break;
                }
            }

            theEvent.z_index = stack.length;

            stack.push(theEvent);

            for (var j = 0; j < stack.length; j++)
            {
                stack[j].compression = Math.max(stack[j].compression, stack.length - 1);
            }
        }

        days.push(column);
    }

    console.log(days);

    var visibleHours = latestHour - earliestHour + 1,
        timelineElement = $('#main-timeline'),
        timelineHeight = timelineElement.height(),
        pixelsPerHour = timelineHeight / visibleHours,
        pixelsPerMinute = pixelsPerHour / 60;

    fillInTimeline(timelineElement, earliestHour, latestHour, pixelsPerHour, json);
    fillInTimeline($('#next-up-timeline'), 0, 23, pixelsPerHour, json);

    var topMinutes = earliestHour * 60,
        nextUpElement = null,
        minutesIntoNextUp = null;

    for (var i = 0; i < 7; i++)
    {
        var day = days[i],
            allDayEvents = day['allday'],
            allDayElement = $("#main-all-day-" + i);

        allDayElement.html("");
        for (var j = 0, count = allDayEvents.length; j < count; j++)
        {
            var element = createEventElement(allDayEvents[j]);
            element.height(MINIMUM_EVENT_HEIGHT, Math.floor(minutes * pixelsPerMinute));
            allDayElement.append(element);
        }

        // Day titles.
        $('#main-header-' + i).html("" + days[i]['title']);

        var mainElement = $('#main-content-' + i),
            dayEvents = day['events'];

        if (day['startDate'].getDate() == today.getDate())
        {
            nextUpElement = $('#next-up-content-0');
            minutesIntoNextUp = (today.getTime() - day['startDate'].getTime()) / 1000 / 60;
        }
        else
            nextUpElement = null;

        mainElement.html("");
        if (nextUpElement)
            nextUpElement.html("");
        for (var j = 0, count = dayEvents.length; j < count; j++)
        {
            var theEvent = dayEvents[j],
                element = createEventElement(theEvent),
                minutesIntoDay = (theEvent.startDate.getTime() - days[i]['startDate'].getTime()) / 1000 / 60,
                minutes = (theEvent.endDate.getTime() - theEvent.startDate.getTime()) / 1000 / 60;

            element.height(Math.max(MINIMUM_EVENT_HEIGHT, Math.floor(minutes * pixelsPerMinute)));
            element.css('top', Math.floor(pixelsPerMinute * (minutesIntoDay - topMinutes)) + 'px');

            // Event stacking
            element.css('zindex', theEvent['z_index']);
            var offsetness = 100 / (1 + theEvent['compression']);
            element.css('width', offsetness + '%');
            var percentOffset = 0;
            if (theEvent['z_index'])
                percentOffset = (offsetness + 1) * theEvent['z_index'];

            element.css('left', percentOffset + '%');

            mainElement.append(element);

            if (nextUpElement)
            {
                element = element.clone();
                // No 'top minutes' in Next Up.
                element.css('top', Math.floor(pixelsPerMinute * minutesIntoDay) + 'px');
                nextUpElement.append(element);
            }
        }

        if (nextUpElement)
        {
            $('#next-up-timeline').height(Math.floor(pixelsPerHour * 24));
            $('#next-up-content-0').height(Math.floor(pixelsPerHour * 24));
            $('#next-up-box .calendar-wrapper').css('top', '0 px');

            if (nextUpTimer)
                window.clearTimeout(nextUpTimer);

            // Allow the screen to draw fully before animating.
            nextUpTimer = window.setTimeout(function() {
                advanceNextUp(pixelsPerMinute, minutesIntoNextUp);
            }, 500);
        }
    }
}

function advanceNextUp(pixelsPerMinute, minutesIntoNextUp)
{
    var nextUpWrapper = $('#next-up-box .calendar-wrapper'),
        oldTop = parseInt($('#next-up-box .calendar-wrapper').css('top').replace("px", "")),
        fastForwardFactor = FAST_FORWARD_NEXT_UP ? 60 : 1;
        minutesSinceUpdate = fastForwardFactor * (new goog.date.DateTime().getTime() - lastUpdateDate.getTime()) / 1000 / 60,
        newTop = Math.floor(-1 * pixelsPerMinute * (minutesIntoNextUp + minutesSinceUpdate));

    // Don't scroll past the bottom.
    newTop = Math.max(newTop, Math.floor(-1 * pixelsPerMinute * 60 * 25 + 0.9 * $("#next-up-box").height()));
    console.log("advancing Next Up to " + minutesSinceUpdate + " minutes from start (" + oldTop + " to " + newTop + " px).");

    nextUpWrapper.animate({
        top: newTop
      },
      Math.abs(newTop - oldTop) > 100 ? 2000 : 500, // Roll in small changes with a snappier animation.
      'easeInOutQuad'
    );
    // For CSS animation, currently commented out in all.css.
    // $('#next-up-box .calendar-wrapper').css('top', (-1 * pixelsPerMinute * minutesIntoNextUp) + 'px');

    // Update again in 15 minutes.
    nextUpTimer = window.setTimeout(function() {
        advanceNextUp(pixelsPerMinute, minutesIntoNextUp);
    }, 15000 * 60 / fastForwardFactor);
}