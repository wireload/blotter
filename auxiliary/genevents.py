#! /usr/bin/python
# coding=utf-8
__author__ = 'kulakov.ilya@gmail.com'

import random
import datetime
import time
import threading
import argparse
import sys
import signal
from calendar import weekday, monthrange

from Foundation import *
from CalendarStore import *


MINIMUM_NUMBER_OF_EVENTS_PER_DAY = 2

DATABASE = [(
                u"Nostalgia is the realization that things weren't as unbearable as they seemed\r\nat the time.\r\n\r\n\t-- Anonymous.",
                u'codehappy'),
            (u'All of me want to cover the whole of you and surround you in my arms.', u'codehappy'),
            (u'I do not fear computers. I fear the lack of them.\r\n\r\n\t-- Isaac Asimov', u'codehappy'),
            (
                u'Good communication is as stimulating as black coffee, and just as hard to\r\nsleep after.\r\n     Anne Morrow Lindbergh',
                u'codehappy'),
            (
                u'08.043\nThe pleasure of false Salafism: the exegete stands above, not below, the ulema.',
                u'contentions'),
            (
                u"Believe everything you hear about the world; nothing is too impossibly bad.\n\t\t-- Honor'\x08e de Balzac",
                u'fortune'),
            (
                u'Saints should always be judged guilty until they are proved innocent.\n\t\t-- George Orwell, "Reflections on Gandhi"',
                u'fortune'),
            (u'About 100 calories are burned during human sexual intercourse.', u'codehappy'),
            (u'Life is like an analogy.', u'fortune'),
            (u"Mother told me to be good but she's been wrong before.", u'fortune'),
            (
                u'Make it right before you make it faster.\n            - The Elements of Programming Style (Kernighan & Plaugher)',
                u'prog_style'),
            (
                u'Mulder: They\'re here, aren\'t they?\nDeep Throat: Mr Mulder, they\'ve been here for a long, long time.\n\n\t"The X-Files: Deep Throat"',
                u'xfiles'),
            (u'I disagree with what you say, but will defend to the death your right to\ntell such LIES!', u'fortune'),
            (u"The modern child will answer you back before you've said anything.\n\t\t-- Laurence J. Peter",
             u'fortune'),
            (u"Proverbs 25:27\nIt is not good to eat too much honey, nor is it honorable to seek \none's own honor.",
             u'bible'),
            (
                u'You often hear the term "meteoric rise" used in reference to someone who\'s up-and-coming. In actuality, meteors don\'t rise, they fall.',
                u'codehappy'),
            (u'Time flies like an arrow.  Fruit flies like a banana.', u'fortune'),
            (u"Simon's Law:\r\n\tEverything put together falls apart sooner or later.", u'codehappy'),
            (
                u'He who has the courage to laugh is almost as much a master of the world\r\nas he who is ready to die.\r\n\t\t-- Giacomo Leopardi',
                u'codehappy'),
            (u'It is better to wear out than to rust out.', u'codehappy'),
            (u'"What countries belong to the Netherlands? France...Belgium?"', u'codehappy'),
            (u'An economist is a man who would marry Farrah Fawcett-Majors for her money.', u'fortune'),
            (u'You know you have a small apartment when Rice Krispies echo.\r\n\r\n\t-- S. Rickly Christian',
             u'codehappy'),
            (u'Give a small boy a hammer and he will find that everything he encounters\nneeds pounding.', u'fortune'),
            (u'You will feel hungry again in another hour.', u'codehappy'),
            (u'Life exists for no known purpose.', u'fortune'),
            (u'02.037\nIdolatry is worse than atheism.', u'contentions'),
            (u'... A booming voice says, "Wrong, cretin!", and you notice that you\nhave turned into a pile of dust.',
             u'fortune'),
            (
                u'AA\x07\x07\x07\x07\x07\x07\x07\x07\x07\x07\x07\x07AAAAAAAAAaaaaaaaaaaaaaaaccccccccckkkkkk!!!!!!!!!\nYou brute!  Knock before entering a ladies room!',
                u'fortune'),
            (u'CHILDREN\'S BOOKS YOU\'LL NEVER SEE:\r\n"You Were an Accident"', u'codehappy'),
            (
                u"Pilots who can see you when dropping you supplies cannot see you when dropping bombs\n\t\t-- Murphy's New Military Laws n\xb09",
                u'murphy'),
            (u"Don't you wish you had more energy... or less ambition?", u'fortune'),
            (
                u"Krusty wore big, floppy shoes, but he's got little feet like all\r\ngood-hearted people.\r\n\r\n\t-- Bart in Krusty Gets Busted",
                u'codehappy'),
            (u'Good news.  Ten weeks from Friday will be a pretty good day.', u'fortune'),
            (
                u"Your bivouac for the night is the spot where got tired of marching that day\n\t\t-- Murphy's New Military Laws n\xb011",
                u'murphy'),
            (u"Gathering threads always break in the middle\n\t\t-- Murphy's Laws of Sewing n\xb018", u'murphy'),
            (
                u'If you float on instinct alone, how can you calculate the buoyancy for\r\nthe computed load?\r\n\t\t-- Christopher Hodder-Williams',
                u'codehappy'),
            (u'Extreme feminine beauty is always disturbing.\n\t\t-- Spock, "The Cloud Minders", stardate 5818.4',
             u'fortune'),
            (
                u'Love makes fools, marriage cuckolds, and patriotism malevolent imbeciles.\n\t\t-- Paul Leautaud, "Passe-temps"',
                u'fortune'),
            (u"Remember, even if you win the rat race -- you're still a rat.", u'fortune'),
            (u'If this is timesharing, give me my share right now.', u'codehappy'),
            (
                u'You can do this in a number of ways.  IBM chose to do all of them.\nWhy do you find that funny?\n\t\t-- D. Taylor, Computer Science 350',
                u'fortune'),
            (u"If you sit down at a poker game and don't see a sucker, get up. You're\r\nthe sucker.", u'codehappy'),
            (u"Save gas, don't use the shell.", u'codehappy'),
            (u'If you continually give you will continually have.', u'fortune'),
            (u'"You\'ve got to have a gimmick if your band sucks."\r\n\t\t-- Gary Giddens', u'codehappy'),
            (u'You learn to write as if to someone else because NEXT YEAR YOU WILL BE\n"SOMEONE ELSE."', u'fortune'),
            (u'Stay out of the road, if you want to grow old.\r\n- Pink Floyd', u'codehappy'),
            (
                u'Proverbs 11:26\nPeople curse the man who hoards grain, but blessing crowns him who is \nwilling to sell.',
                u'bible'),
            (u'The individual is the key, the final effective unit of all biological processes.\n\n-PARDOT KYNES',
             u'dune'),
            (u'Virtue is not left to stand alone.  He who practices it will have neighbors.\r\n\t\t-- Confucius',
             u'codehappy'),
            (u'There are four cars and eleven lightposts on the back of a $10 bill.', u'codehappy'),
            (u'He who has but four and spends five has no need for a wallet.', u'codehappy'),
            (u"Woman's advice has little value, but he who won't take it is a fool.\n\t\t-- Cervantes", u'fortune'),
            (
                u'"I\'ve got a hankerin\' for some pork products."\r\n\r\n\t-- Krusty in Krusty Gets Busted',
                u'codehappy'),
            (u'Cursor, n.:\r\n\tOne whose program will not run.\r\n\t\t-- Robb Russon', u'codehappy'),
            (u"If graphics hackers are so smart, why can't they get the bugs out of\r\nfresh paint?", u'codehappy'),
            (u'Counting time in not as important as making time count.', u'codehappy'),
            (u'Who dat who say "who dat" when I say "who dat"?\r\n\t\t-- Hattie McDaniel', u'codehappy'),
            (u'"I\'d love to go out with you, but the man on television told me to say tuned."', u'codehappy'),
            (u'Any philosophy that can be put "in a nutshell" belongs there.\r\n\t\t-- Sydney J. Harris', u'codehappy'),
            (u'There are few people more often in the wrong than those who cannot endure\r\nto be thought so.',
             u'codehappy'),
            (u"Don't assume that every sad-eyed woman has loved and lost -- she may\r\nhave got him.", u'codehappy'),
            (u"There are three kinds of people in this world, ones you can count on, and \nones that can't count.",
             u'oneliners'),
            (u"Greener's Law:\r\nNever argue with a man who buys ink by the barrel.", u'codehappy'),
            (u'01.084\nFree will secularises by authenticating the alterities.', u'contentions'),
            (u'\x07\x07\x07\x07\t*** System shutdown message from root ***\r\n\r\nSystem going down in 60 seconds',
             u'codehappy'),
            (
                u"When camping in late fall or winter, your underwear will stay at approximately 35\n\t\t-- Murphy's Laws of Camping n\xb023",
                u'murphy'),
            (u'I think my career is ruined!', u'codehappy'),
            (u'Without fools there would be no wisdom.', u'fortune'),
            (u'Pay no attention to what the critics say. A statue has never been erected in\r\nhonour of a critic.',
             u'codehappy'),
            (u'It takes all kinds to fill the freeways.\r\n\t\t-- Crazy Charlie', u'codehappy'),
            (
                u'And we heard him exclaim\r\nAs he started to roam:\r\n"I\'m a hologram, kids,\r\nplease don\'t try this at home!\'"\r\n\t\t-- Bob Violence',
                u'codehappy'),
            (u'Heard from a tourist at Banff National Park:\r\n\r\n"Is there anywhere I can see the bears pose?"',
             u'codehappy'),
            (
                u"If you make people think they're thinking, they'll love you; but if you\nreally make them think they'll hate you.",
                u'fortune'),
            (u'Twenty of the suckiest minutes of my life.\n\n\t\t-- Homer Simpson\n\t\t   Burns, Baby Burns',
             u'simpsons_homer'),
            (u'Customer: "I want a Penitum processor, because those Pentiums are just no \r\n  good."', u'codehappy'),
            (u'Why are you so hard to ignore?', u'codehappy'),
            (u'You may be an engineer if....\r\nIf you can quote scenes from any Monty Python movie', u'codehappy'),
            (u'In Casablanca, Humphrey Bogart never said "Play it again, Sam."', u'codehappy'),
            (
                u'The universe is like a safe to which there is a combination -- but the\r\ncombination is locked up in the safe.\r\n\t\t-- Peter DeVries',
                u'codehappy'),
            (
                u'Quality control, n.:\n\tAssuring that the quality of a product does not get out of hand\n\tand add to the cost of its manufacture or design.',
                u'fortune'),
            (u"Murphy's Law is recursive. Washing your car to make it rain doesn't\r\nwork.", u'codehappy'),
            (u'To teach is to learn.\r\n\r\n\t-- Japanese Proverb', u'codehappy'),
            (u'BEWARE!  People acting under the influence of human nature.', u'fortune'),
            (
                u'Q. Half of all Americans live within 50 miles of what?\r\nA. Their birthplace. This is called propinquity.',
                u'codehappy'),
            (u'Actual Newspaper Headline:\r\n\r\nNever Withhold Herpes Infection from Loved One', u'codehappy'),
            (u'Small things make base men proud.\n\t\t-- William Shakespeare, "Henry VI"', u'literature'),
            (
                u"There are two major products that come out of Berkeley: LSD and UNIX.\r\nWe don't believe this to be a coincidence.\r\n\t\t-- Jeremy S. Anderson",
                u'codehappy'),
            (u'Albert Einstein was offered the presidency of Israel in 1952.', u'codehappy'),
            (u'She is not refined.  She is not unrefined.  She keeps a parrot.\r\n\t\t-- Mark Twain', u'codehappy'),
            (u'08.072\nGaia is not ghaya, it is matrix.', u'contentions'),
            (u'Let the meek inherit the earth -- they have it coming to them.\r\n\t\t-- James Thurber', u'codehappy'),
            (u'To have died once is enough.\n\t\t-- Publius Vergilius Maro (Virgil)', u'fortune'),
            (u"mathematician, n.:\r\n\tSome one who believes imaginary things appear right before your _\x08i's.",
             u'codehappy'),
            (u"A homeowner's reach should exceed his grasp, or what's a weekend for?", u'fortune'),
            (u"If at first you don't succeed, you must be using Windows.", u'humorix_misc'),
            (u'A Linux machine! because a 486 is a terrible thing to waste!\n(By jjs@wintermute.ucr.edu, Joe Sloan)',
             u'fortune'),
            (
                u'"No one appreciates the very special genius of your conversation as the dog \r\ndoes."\r\nChristopher Morley',
                u'codehappy')]


def random_date_range(start, end):
    start_time = time.mktime(start.timetuple())
    end_time = time.mktime(end.timetuple())
    new_start_time = start_time + random.random() * (end_time - start_time)
    new_end_time = new_start_time + random.choice([1.0, 1.0, 1.0, 2.0, 4.0, 8.0]) * 3600
    return datetime.datetime.fromtimestamp(new_start_time), datetime.datetime.fromtimestamp(new_end_time)


def day_date_range(date):
    start = datetime.datetime(date.year, date.month, date.day)
    end = start + datetime.timedelta(days=1)
    return start, end


def week_date_range(date):
    start = datetime.datetime(date.year, date.month, date.day)
    start -= datetime.timedelta(days=weekday(start.year, start.month, start.day))
    end = start + datetime.timedelta(days=7)
    return start, end


def month_date_range(date):
    start = datetime.datetime(date.year, date.month, 1)
    weekday, days_count = monthrange(date.year, date.month)
    end = start + datetime.timedelta(days=days_count)
    return start, end


def calendar_identifiers():
    store = CalCalendarStore.defaultCalendarStore()
    predicate = NSPredicate.predicateWithFormat_("isEditable == YES")
    calendars = store.calendars().filteredArrayUsingPredicate_(predicate)
    return zip(calendars.valueForKey_('title'), calendars.valueForKey_("uid"))


def calendar_with_uid(identifier):
    store = CalCalendarStore.defaultCalendarStore()
    return store.calendarWithUID_(identifier)


def generate_events(calendar, start, end):
    predicate = CalCalendarStore.eventPredicateWithStartDate_endDate_calendars_(start, end, [calendar])
    store = CalCalendarStore.defaultCalendarStore()
    events = store.eventsWithPredicate_(predicate)
    min_events = (end - start).days * MINIMUM_NUMBER_OF_EVENTS_PER_DAY

    def make_event(calendar, start, end):
        event = CalEvent.event()
        event.setCalendar_(calendar)

        event_start, event_end = random_date_range(start, end)
        event.setStartDate_(event_start)
        event.setEndDate_(event_end)

        title, location = random.choice(DATABASE)
        event.setTitle_(title)
        event.setLocation_(location)
        return event

    def add_event(event):
        print "Add event"
        return store.saveEvent_span_error_(event, CalSpanThisEvent, None)

    def remove_event(event):
        print "Remove event"
        return store.removeEvent_span_error_(event, CalSpanThisEvent, None)

    def move_event(event, start, end):
        print "Move event"
        event_start, event_end = random_date_range(start, end)
        event.setStartDate_(event_start)
        event.setEndDate_(event_end)
        return store.saveEvent_span_error_(event, CalSpanThisEvent, None)

    def update_event(event):
        print "Update event"
        pass

    pool = NSAutoreleasePool.alloc().init()
    while len(events) < min_events:
        event = make_event(calendar, start, end)
        result, error = add_event(event)
        if result:
            events.append(event)
    rand = random.randint(0, 5)

    if rand == 0:
        add_event(make_event(calendar, start, end))
    elif rand == 1:
        move_event(random.choice(events), start, end)
    elif rand == 2:
        update_event(random.choice(events))
    else:
        event = random.choice(events)
        remove_event(event)
        events.remove(event)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate events in calendar with uid within selected range.')
    parser.add_argument('uid', help='UID of a calendar. Pass "list" to show all avaialable calendars',
        default='invalid')
    parser.add_argument('--range', choices=['day', 'week', 'month'],
        help='generate events within given range (default - week)', default='week')
    parser.add_argument('--interval', type=int, help='interval in seconds between event updates', default=5)

    args = parser.parse_args()

    if args.range == 'day':
        start, end = day_date_range(datetime.datetime.now())
    elif args.range == 'week':
        start, end = week_date_range(datetime.datetime.now())
    elif args.range == 'month':
        start, end = month_date_range(datetime.datetime.now())
    else:
        print >> sys.stderr, "Date range is wrong."
        sys.exit(1)

    if args.uid != 'list':
        calendar = calendar_with_uid(args.uid)

        if calendar is None:
            print >> sys.stderr, "Calendar with uid '{uid}' is not found.".format(uid=args.uid)
            sys.exit(1)

        print "Calendar: {title}".format(title=calendar.title(), uid=calendar.uid())
        print "Date range: ({start}, {end})".format(start=str(start), end=str(end))
        print "Interval: {interval} sec".format(interval=args.interval)
        while True:
            generate_events(calendar, start, end)
            time.sleep(args.interval)
    else:
        print "List of available calendars:"
        print "\n".join(item[0] + "\t" + item[1] for item in calendar_identifiers())
