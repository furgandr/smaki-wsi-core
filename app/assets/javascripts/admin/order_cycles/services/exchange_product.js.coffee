angular.module('admin.orderCycles').factory('ExchangeProduct', ($resource) ->
  ExchangeProductResource = $resource('/api/v0/exchanges/:exchange_id/products.json', {}, {
    'index': { method: 'GET' }
    'variant_count': { method: 'GET', params: { action_name: "variant_count" }}
  })
  {
    ExchangeProductResource: ExchangeProductResource

    index: (params={}, callback=null, errorCallback=null) ->
      ExchangeProductResource.index params, (data) =>
        (callback || angular.noop)(data.products, data.pagination?.pages, data.pagination?.results)
      , (response) =>
        (errorCallback || angular.noop)(response)

    countVariants: (params={}, callback=null, errorCallback=null) ->
      ExchangeProductResource.variant_count params, (data) =>
        (callback || angular.noop)(data.count)
      , (response) =>
        (errorCallback || angular.noop)(response)
  })
