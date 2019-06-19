#!/bin/env python3

from datetime import datetime
import requests
import os

def timestamp_time(stamp):
	return decimal_time(int(stamp[11:13]), int(stamp[14:16]), int(stamp[17:19]))

def current_time():

	h = int(datetime.now().strftime("%H"))
	m = int(datetime.now().strftime("%M"))
	s = int(datetime.now().strftime("%S"))
	return decimal_time(h, m, s)

def decimal_time(h, m, s):

	return h + m / 60.0 + s / 3600.0

def location():

	ip = requests.get('http://ip-api.com/json').json()
	latitude = ip['lat']
	longitude = ip['lon']
	return (latitude, longitude)

def sun(location):

	ip = requests.get('https://api.sunrise-sunset.org/json?lat=%s&lng=%s&formatted=0&date=today' % location).json()['results']
	return {
		'sunrise'	: timestamp_time(ip['sunrise']),
		'noon'		: timestamp_time(ip['solar_noon']),
		'sunset'	: timestamp_time(ip['sunset']),
		'midnight'	: (timestamp_time(ip['solar_noon']) + 12) % 24
	}

def points(sun):

	return [
		sun['sunrise'] * 0.8,
		sun['sunrise'],
		sun['sunrise'] + (sun['noon'] - sun['sunrise']) * 0.3,
		sun['noon'],
		sun['noon'] + (sun['sunset'] - sun['noon']) * 0.9,
		sun['sunset'],
		sun['sunset'] + (sun['midnight'] - sun['sunset']) * 0.3,
		sun['midnight']
	]

try:
	points = points(sun(location()))
except:
	points = [5, 6, 7, 12, 19, 20, 21, 0]

remaining = list(filter(lambda x: x[1] >= current_time(), enumerate(points)))

current = 7
if len(remaining) > 0:
	# current = max((remaining[0][0] - 1, 0))
	current = remaining[0][0]

# print(points, remaining, current)

print(os.path.dirname(os.path.realpath(__file__)) + '/images/' + str(current) + '.png')