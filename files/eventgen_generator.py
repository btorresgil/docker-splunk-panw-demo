from __future__ import division
from generatorplugin import GeneratorPlugin
import os
import logging
import datetime, time
import random
import copy
from eventgenoutput import Output


class PANWGenerator(GeneratorPlugin):
    def __init__(self, sample):
        GeneratorPlugin.__init__(self, sample)

        # Logger already setup by config, just get an instance
        logger = logging.getLogger('eventgen')
        from eventgenconfig import EventgenAdapter
        adapter = EventgenAdapter(logger, {'module': 'PANWGenerator',
                                           'sample': sample.name})
        globals()['logger'] = adapter

        from eventgenconfig import Config
        globals()['c'] = Config()

    def gen(self, count, earliest, latest, samplename=None):
        # 2/10/14 CS set s to our local copy of the sample
        s = self._samples[samplename]
        self._sample = s

        # 6/9/14 CS If we get an exception loading the sample, fail
        try:
            s.loadSample()
        except TypeError:
            logger.error("Error loading sample file for sample '%s'" % s.name)
            return

        logger.debug(
            "Generating sample '%s' in app '%s' with count %d, et: '%s', lt '%s'" % (
            s.name, s.app, count, earliest, latest))
        startTime = datetime.datetime.now()

        # If we're random, fill random events from sampleDict into eventsDict
        if s.randomizeEvents:
            eventsDict = []
            sdlen = len(s.sampleDict)
            logger.debugv(
                "Random filling eventsDict for sample '%s' in app '%s' with %d events" % (
                s.name, s.app, count))
            # Count is -1, replay the whole file, but in randomizeEvents I think we'd want it to actually
            # just put as many events as there are in the file
            if count == -1:
                count = sdlen
            while len(eventsDict) < count:
                eventsDict.append(s.sampleDict[random.randint(0, sdlen - 1)])
        # If we're bundlelines, create count copies of the sampleDict
        elif s.bundlelines:
            eventsDict = []
            logger.debugv(
                "Bundlelines, filling eventsDict for sample '%s' in app '%s' with %d copies of sampleDict" % (
                s.name, s.app, count))
            for x in xrange(count):
                eventsDict.extend(s.sampleDict)
        # Otherwise fill count events into eventsDict or keep making copies of events out of sampleDict until
        # eventsDict is as big as count
        else:
            # If count is -1, play the whole file, else grab a subset
            if count == -1:
                count = len(s.sampleDict)
            eventsDict = s.sampleDict[0:count]

            ## Continue to fill events array until len(events) == count
            if len(eventsDict) < count:
                logger.debugv(
                    "Events fill for sample '%s' in app '%s' less than count (%s vs. %s); continuing fill" % (
                    s.name, s.app, len(eventsDict), count))
                logger.debugv("Current eventsDict: %s" % eventsDict)
                # run a modulus on the size of the eventdict to figure out what the last event was.  Populate to count
                # from there.
                while len(eventsDict) < count:
                    nextEventToUse = s.sampleDict[
                        len(eventsDict) % len(s.sampleDict)]
                    logger.debugv("Next event to add: %s" % nextEventToUse)
                    eventsDict.append(nextEventToUse)
                logger.debugv(
                    "Events fill complete for sample '%s' in app '%s' length %d" % (
                    s.name, s.app, len(eventsDict)))

        eventcount = 0

        if s.bundlelines:
            events_combined = "<BREAK>".join([event['_raw'] for event in eventsDict])

            mvhash = {}

            ## Iterate tokens
            for token in s.tokens:
                token.mvhash = mvhash
                logger.debugv(
                    "Sending event to token replacement: Event:{0} Token:{1}".format(
                        events_combined, token))
                events_combined = token.replace(events_combined, et=earliest, lt=latest, s=s)
                logger.debugv("finished replacing token")

            raw_strings = events_combined.split("<BREAK>")

            for idx, targetevent in enumerate(eventsDict):

                if s.timestamp == None:
                    s.timestamp = s.now()
                l = [{'_raw': raw_strings[idx],
                      'index': targetevent['index'],
                      'host': targetevent['host'],
                      'hostRegex': s.hostRegex,
                      'source': targetevent['source'],
                      'sourcetype': targetevent['sourcetype'],
                      '_time': int(time.mktime(s.timestamp.timetuple()))}]
                logger.debugv("Finished Processing event: %s" % eventcount)
                eventcount += 1
                self._out.bulksend(l)
                s.timestamp = None
        else:
            for targetevent in eventsDict:
                try:
                    event = targetevent['_raw']

                    # Maintain state for every token in a given event
                    # Hash contains keys for each file name which is assigned a list of values
                    # picked from a random line in that file
                    mvhash = {}

                    ## Iterate tokens
                    for token in s.tokens:
                        token.mvhash = mvhash
                        # logger.debugv("Replacing token '%s' of type '%s' in event '%s'" % (token.token, token.replacementType, event))
                        logger.debugv(
                            "Sending event to token replacement: Event:{0} Token:{1}".format(
                                event, token))
                        event = token.replace(event, et=earliest, lt=latest, s=s)
                        logger.debugv("finished replacing token")
                        if token.replacementType == 'timestamp' and s.timeField != '_raw':
                            s.timestamp = None
                            token.replace(targetevent[s.timeField],
                                          et=s.earliestTime(), lt=s.latestTime(),
                                          s=s)
                    if (s.hostToken):
                        # clear the host mvhash every time, because we need to re-randomize it
                        s.hostToken.mvhash = {}

                    host = targetevent['host']
                    if (s.hostToken):
                        host = s.hostToken.replace(host, s=s)

                    if s.timestamp == None:
                        s.timestamp = s.now()
                    l = [{'_raw': event,
                          'index': targetevent['index'],
                          'host': host,
                          'hostRegex': s.hostRegex,
                          'source': targetevent['source'],
                          'sourcetype': targetevent['sourcetype'],
                          '_time': int(time.mktime(s.timestamp.timetuple()))}]
                    logger.debugv("Finished Processing event: %s" % eventcount)
                    eventcount += 1
                    self._out.bulksend(l)
                    s.timestamp = None
                except Exception as e:
                    raise e

        endTime = datetime.datetime.now()
        timeDiff = endTime - startTime
        timeDiffFrac = "%d.%06d" % (timeDiff.seconds, timeDiff.microseconds)
        logger.debugv("Interval complete, flushing feed")
        self._out.flush(endOfInterval=True)
        logger.debug(
            "Generation of sample '%s' in app '%s' completed in %s seconds." % (
            s.name, s.app, timeDiffFrac))


def load():
    return PANWGenerator
