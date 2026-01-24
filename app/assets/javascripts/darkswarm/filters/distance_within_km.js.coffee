angular.module('Darkswarm').filter 'distanceWithinKm', ->
  (enterprises, range) ->
    enterprises ||= []
    return enterprises if range == 'all' || !range?

    range = parseFloat(range)
    enterprises.filter (enterprise) ->
      enterprise.distance / 1000 <= range
