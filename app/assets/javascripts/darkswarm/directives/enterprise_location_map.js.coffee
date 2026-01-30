angular.module('Darkswarm').directive 'enterpriseLocationMap', ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    map = null
    marker = null
    initialized = false

    initMap = ->
      return if initialized
      lat = parseFloat(attrs.lat)
      lng = parseFloat(attrs.lng)
      return if isNaN(lat) || isNaN(lng)

      element.addClass('enterprise-location-map--ready')

      map = L.map(element[0],
        zoomControl: true
        scrollWheelZoom: false
        dragging: true
      )
      L.tileLayer.provider('OpenStreetMap.Mapnik').addTo(map)
      marker = L.marker([lat, lng]).addTo(map)
      map.setView([lat, lng], 13)

      element.on 'mouseenter', ->
        map?.scrollWheelZoom.enable()
      element.on 'mouseleave', ->
        map?.scrollWheelZoom.disable()

      initialized = true

    attrs.$observe 'lat', ->
      initMap()
    attrs.$observe 'lng', ->
      initMap()

    scope.$on '$destroy', ->
      if map?
        map.remove()
        map = null
        marker = null
