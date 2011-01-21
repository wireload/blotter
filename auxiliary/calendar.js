// The goal here is to create 7 day columns, splitting multiday events as needed,
// while finding out the earliest and latest event time in the set and preparing
// positioning data for overlapping events.

goog.require('goog.date');

jQuery.easing.def = "easeInOutQuad";

jQuery.fn.reverse = function() {
    return this.pushStack(this.get().reverse(), arguments);
};

function capitaliseFirstLetter(string)
{
    return string.charAt(0).toUpperCase() + string.slice(1);
}

function bottomOfElement(element)
{
    var pos = element.position();
    if (pos === null)
        return 0;
    return pos.top + element.height();
}

/*
    Make children of element into one-liners with ellipsis, or entirely hide
    children until the given element fits within its parent.
*/
function fitWholeChildrenOnly(element)
{
    var availableHeight = element.parent().height();

    // Reset any changes previously made by fitWholeChildrenOnly.
    element.children().show();
    element.children().removeClass('single-ellipsis');

    //  Prune from the back.
    element.children().reverse().each(function()
    {
        if (bottomOfElement(element) > availableHeight)
        {
            $(this).addClass('single-ellipsis');

            // Was the single line ellipsis sufficient or do we need more
            // drastic measures?
            if (bottomOfElement(element) > availableHeight)
                $(this).hide();
        }
    });
}

/*
    Allow all day events to become multiline when there's space for that. Add
    ellipsis if not.
*/
function layoutAllDayEvents(element)
{
    // The default is single line events with ellipsis. Then we'll
    // expand from the top when possible.

    element.find('.event').each(function()
    {
        var topWrapper = $(this).parent().parent();
        topWrapper.show();
        $(this).addClass('single-ellipsis');
        topWrapper.height($(this).height() + 16);
    });

    var availableHeight = element.height(),
        lastVisibleTopWrapper = null;

    // If we don't fit now we must remove items.
    element.find('.event').reverse().each(function()
    {
        var topWrapper = $(this).parent().parent();
        if (bottomOfElement(topWrapper) > availableHeight)
            topWrapper.hide();
        else if (lastVisibleTopWrapper === null)
            lastVisibleTopWrapper = topWrapper;
    });

    // Now that we have hidden all elements which definitely
    // will not fit, allow the remaining elements to expand.
    element.find('.event').each(function()
    {
        var topWrapper = $(this).parent().parent();

        $(this).removeClass('single-ellipsis');
        topWrapper.height($(this).height() + 16);

        if (bottomOfElement(lastVisibleTopWrapper) >= availableHeight)
        {
            $(this).addClass('single-ellipsis');
            topWrapper.height($(this).height() + 16);
        }
    });
}

/**
    Implement ellipsis for regular day events.
*/
function layoutDayEvent(eventElement)
{
    // This case is pretty easy because events have fixed height. So basically
    // just remove stuff until it fits - no need to balance with other events.
    var innerWrapper = eventElement.find('.event'),
        availableHeight = innerWrapper.height(),
        locationElement = innerWrapper.find('.location');

    // Cut the location element?
    if (locationElement && bottomOfElement(locationElement) >= availableHeight)
        locationElement.hide();

    // Ellipsify the title?
    var titleElement = innerWrapper.find('.title');
    if (bottomOfElement(titleElement) >= availableHeight)
    {
        titleElement.addClass('ellipsis').addClass('multiline');
        titleElement.height(availableHeight);
        titleElement.ellipsis();
    }
}

function implementSizingHacks()
{
    var infoHeight = $(".info-boxes-space").height();
    $("#to-do-box").height(infoHeight / 2 - 20);

    fitWholeChildrenOnly($("#to-do-box ul"));
    for (var i = 0; i < 7; i++)
    {
        layoutAllDayEvents($("#main-all-day-" + i));
    }
}

$(document).ready(implementSizingHacks);
$(window).resize(implementSizingHacks);

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

var MINIMUM_EVENT_HEIGHT = 30,
    FAST_FORWARD_NEXT_UP = false,

    lastUpdateDate = null,
    nextUpTimer = null;

function updateDateElement(dateElement, todayDate)
{
    dateElement.find(".date-date").text(todayDate.getDate());
    dateElement.find(".date-month-year").text(date_formatter.MonthAndYear(todayDate.getTime()));
    dateElement.find(".date-day").text(date_formatter.Weekday(todayDate.getTime()));
}

function updateTasksElement(tasksElement, json)
{
    tasksElement.html("");
    for (var i = 0, count = json.tasks.length; i < count; i++)
    {
        var task = json.tasks[i];
        tasksElement.append($("<li></li>").text(task.title));
    }
}

/**
    Represent a week in the calendar, with events laid out into a per day data structure
    with various data pieces precalculated.
*/
var CalendarWeek = function(startDate, json)
{
    this.startDate = startDate;
    this.days = [];
    this.earliestHour = 9;
    this.latestHour = 17;

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

                if (eventStart.getHours() < this.earliestHour)
                    this.earliestHour = eventStart.getHours();
                if (eventEnd.getHours() > this.latestHour)
                    this.latestHour = eventEnd.getHours();
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

        this.days.push(column);
    }

    this.getVisibleHours = function()
    {
        return this.latestHour - this.earliestHour + 1
    }

    this.stackEvents = function(minimumEventDuration)
    {
        // Now that we have all the events split and sorted, find side by side events.
        for (var i = 0, count = this.days.length; i < count; i++)
        {
            var day = this.days[i];
            this.stackEventsDay(minimumEventDuration, day);
        }
    }

    this.stackEventsDay = function(minimumEventDuration, day)
    {
        var calculateEffectiveEndDate = function(theEvent)
        {
            var startDate = theEvent.startDate,
                endDate = theEvent.endDate,
                effectiveEndDate = startDate.clone();
            effectiveEndDate.add(new goog.date.Interval(goog.date.Interval.SECONDS, minimumEventDuration));
            return endDate > effectiveEndDate ? endDate : effectiveEndDate;
        }

        var stack = [];
        for (var i = 0, count = day['events'].length; i < count; i++)
        {
            var theEvent = day['events'][i];

            for (var j = 0; j < stack.length; j++)
            {
                if (calculateEffectiveEndDate(stack[j]) <= theEvent.startDate)
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
    }
}

function updateAllDayElement(allDayElement, day)
{
    var allDayEvents = day['allday'];

    allDayElement.html("");
    for (var i = 0, count = allDayEvents.length; i < count; i++)
    {
        var element = createEventElement(allDayEvents[i]);
        // Will be calculated by the layout fixer later.
        allDayElement.append(element);
    }
}

function updateDayHeaderElement(headerElement, day, isToday)
{
    // Day titles. Capitalise first letter since day names are lowercase in some locales
    // but we still want capitalised headers.
    headerElement.html(capitaliseFirstLetter("" + day['title']));
    if (isToday)
        headerElement.addClass('today');
    else
        headerElement.removeClass('today');
}

function updateDayElement(mainElement, day, pixelsPerMinute, topMinutes)
{
    var dayEvents = day['events'];

    mainElement.html("");
    for (var j = 0, count = dayEvents.length; j < count; j++)
    {
        var theEvent = dayEvents[j],
            element = createEventElement(theEvent),
            minutesIntoDay = (theEvent.startDate.getTime() - day['startDate'].getTime()) / 1000 / 60,
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

        layoutDayEvent(element);
    }
}

function update(json)
{
    if (typeof(json) == 'string')
        json = $.parseJSON(json);

    lastUpdateDate = new goog.date.DateTime();
    FAST_FORWARD_NEXT_UP = json.fastForwardNextUp;

    var startDate       = goog.date.fromIsoString(json.beginningDate),
        endDate         = goog.date.fromIsoString(json.endDate),
        today           = goog.date.fromIsoString(json.date);

    updateDateElement($(".info .date"), today);

    updateTasksElement($("#to-do-box .tasks"), json)

    var calendarWeek = new CalendarWeek(startDate, json),
        visibleHours = calendarWeek.getVisibleHours(),
        timelineElement = $('#main-timeline'),
        nextUpTimelineElement = $('#next-up-timeline'),
        timelineHeight = timelineElement.height() || $('#next-up-timeline').height(),
        pixelsPerHour = timelineHeight / visibleHours,
        pixelsPerMinute = pixelsPerHour / 60;

    // When stacking events, the effective length of each event in seconds needs
    // to be known, which is determined by how many seconds the MINIMUM_EVENT_HEIGHT
    // is.
    calendarWeek.stackEvents(60 * MINIMUM_EVENT_HEIGHT / pixelsPerMinute);

    fillInTimeline(timelineElement, calendarWeek.earliestHour, calendarWeek.latestHour, pixelsPerHour, json);
    fillInTimeline($('#next-up-timeline'), 0, 23, pixelsPerHour, json);

    var topMinutes = calendarWeek.earliestHour * 60;

    for (var i = 0; i < 7; i++)
    {
        var day = calendarWeek.days[i],
            isToday = day['startDate'].getDate() == today.getDate();

        updateAllDayElement($("#main-all-day-" + i), day);
        updateDayHeaderElement($('#main-header-' + i), day, isToday);

        updateDayElement($('#main-content-' + i), day, pixelsPerMinute, topMinutes);

        if (isToday)
        {
            var nextUpElement = $('#next-up-content-0');
            // No 'top minutes' in Next Up.
            updateDayElement(nextUpElement, day, pixelsPerMinute, 0);

            $('#next-up-timeline').height(Math.floor(pixelsPerHour * 24));
            $('#next-up-content-0').height(Math.floor(pixelsPerHour * 24));
            $('#next-up-box .calendar-wrapper').css('top', '0 px');

            if (nextUpTimer)
                window.clearTimeout(nextUpTimer);

            // Allow the screen to draw fully before animating.
            var minutesIntoNextUp = (today.getTime() - day['startDate'].getTime()) / 1000 / 60;
            nextUpTimer = window.setTimeout(function() {
                advanceNextUp(pixelsPerMinute, minutesIntoNextUp);
            }, 100);
        }
    }

    implementSizingHacks();
}

function advanceNextUp(pixelsPerMinute, minutesIntoNextUp)
{
    var nextUpWrapper = $('#next-up-box .calendar-wrapper'),
        availableHeight = nextUpWrapper.parent().height(),
        columnHeight = 24 * 60 * pixelsPerMinute,
        oldTop = parseInt($('#next-up-box .calendar-wrapper').css('top').replace("px", "")),
        fastForwardFactor = FAST_FORWARD_NEXT_UP ? 60 : 1;
        minutesSinceUpdate = fastForwardFactor * (new goog.date.DateTime().getTime() - lastUpdateDate.getTime()) / 1000 / 60,
        newTop = Math.floor(-1 * pixelsPerMinute * (minutesIntoNextUp + minutesSinceUpdate));

    // Don't scroll past the bottom.
    newTop = Math.max(newTop, Math.floor(-1 * columnHeight + availableHeight - 35)); // -35 for the bottom fade.
    // console.log("advancing Next Up to " + minutesSinceUpdate + " minutes from start (" + oldTop + " to " + newTop + " px).");

    // Only animate small changes - larger animations cause flickering in the transparent version.
    if (Math.abs(newTop - oldTop) < 100)
    {
        nextUpWrapper.animate({
            top: newTop
          },
          2000,
          'easeInOutQuad'
        );
    }
    else
    {
        nextUpWrapper.css('top', newTop);
    }
    // For CSS animation, currently commented out in all.css.
    // $('#next-up-box .calendar-wrapper').css('top', (-1 * pixelsPerMinute * minutesIntoNextUp) + 'px');

    // Update again in 15 minutes.
    nextUpTimer = window.setTimeout(function() {
        advanceNextUp(pixelsPerMinute, minutesIntoNextUp);
    }, 15000 * 60 / fastForwardFactor);
}

function updateWhenReady(json)
{
    $(document).ready(function()
    {
        try {
            update(json);
        } catch (e) {
            console.log(e.toString());
        }
    });
}
