angular.module('Darkswarm').controller "EnterprisesCtrl", ($scope, $rootScope, $timeout, $location, $filter, Enterprises, Search, $document, HashNavigation, FilterSelectorsService, EnterpriseModal, OrderCycleResource, enterpriseMatchesQueryFilter, distanceWithinKmFilter) ->
  $scope.Enterprises = Enterprises
  $scope.producers_to_filter = Enterprises.producers
  $scope.filterSelectors = FilterSelectorsService.createSelectors()
  $scope.query = Search.search()
  $scope.openModal = EnterpriseModal.open
  $scope.activeTaxons = []
  $scope.show_profiles = false
  $scope.show_closed = false
  $scope.filtersActive = false
  $scope.distanceMatchesShown = false
  $scope.closed_shops_loading = false
  $scope.closed_shops_loaded = false
  $scope.distanceRange = 50
  $scope.productsLoading = false
  $scope.visibleProducts = []
  $scope.enterpriseProducts = {}
  $scope.productsLimit = 6
  $scope.nameMatchesFiltered = []
  $scope.distanceMatchesFiltered = []
  $scope.visibleMatchesFiltered = []

  $scope.$watch "query", (query)->
    $scope.resetSearch(query)

  $scope.$watch "distanceRange", ->
    $scope.filterEnterprises()
    $scope.updateVisibleMatches()

  $scope.resetSearch = (query) ->
    Enterprises.flagMatching query
    Search.search query
    $rootScope.$broadcast 'enterprisesChanged'
    $scope.distanceMatchesShown = false

    $timeout ->
      Enterprises.calculateDistance query, $scope.firstNameMatch()
      $rootScope.$broadcast 'enterprisesChanged'
      $scope.closed_shops_loading = false

  $timeout ->
    if $location.search()['show_closed']?
      $scope.showClosedShops()

  $scope.$watch "filtersActive", (value) ->
    $scope.$broadcast 'filtersToggled'

  $rootScope.$on "enterprisesChanged", ->
    $scope.filterEnterprises()
    $scope.updateVisibleMatches()


  # When filter settings change, this could change which name match is at the top, or even
  # result in no matches. This affects the reference point that the distance matches are
  # calculated from, so we need to recalculate distances.
  $scope.$watch '[activeTaxons, activeProperties, shippingTypes, show_profiles, show_closed]', ->
    $timeout ->
      Enterprises.calculateDistance $scope.query, $scope.firstNameMatch()
      $rootScope.$broadcast 'enterprisesChanged'
  , true


  $rootScope.$on "$locationChangeSuccess", (newRoute, oldRoute) ->
    if HashNavigation.active "hubs"
      $document.scrollTo $("#hubs"), 100, 200


  $scope.filterEnterprises = ->
    es = Enterprises.hubs
    $scope.nameMatches = enterpriseMatchesQueryFilter(es, true)
    noNameMatches = enterpriseMatchesQueryFilter(es, false)
    $scope.distanceMatches = distanceWithinKmFilter(noNameMatches, $scope.distanceRange)


  $scope.updateVisibleMatches = ->
    $scope.visibleMatches = if $scope.nameMatches.length == 0 || $scope.distanceMatchesShown
      $scope.nameMatches.concat $scope.distanceMatches
    else
      $scope.nameMatches
    $scope.nameMatchesFiltered = $scope.applyEnterpriseFilters($scope.nameMatches)
    $scope.distanceMatchesFiltered = $scope.applyEnterpriseFilters($scope.distanceMatches)
    $scope.visibleMatchesFiltered = if $scope.nameMatchesFiltered.length == 0 || $scope.distanceMatchesShown
      $scope.nameMatchesFiltered.concat $scope.distanceMatchesFiltered
    else
      $scope.nameMatchesFiltered
    $scope.loadProductsForVisibleMatches()

  $scope.loadProductsForVisibleMatches = ->
    $scope.visibleProducts = []
    pending = 0
    for enterprise in $scope.visibleMatchesFiltered when enterprise.current_order_cycle_id?
      if $scope.enterpriseProducts[enterprise.id]?
        $scope.addProducts(enterprise, $scope.enterpriseProducts[enterprise.id])
        continue

      pending += 1
      params =
        id: enterprise.current_order_cycle_id
        distributor: enterprise.id
        per_page: $scope.productsLimit

      OrderCycleResource.products params, (data) =>
        products = ( $scope.prepareProduct(product, enterprise) for product in data )
        $scope.enterpriseProducts[enterprise.id] = products
        $scope.addProducts(enterprise, products)
        pending -= 1
        $scope.productsLoading = pending > 0

    $scope.productsLoading = pending > 0

  $scope.prepareProduct = (product, enterprise) ->
    supplier_id = product.variants?[0]?.supplier?.id
    producer = if supplier_id? then Enterprises.enterprises_by_id[supplier_id] else null
    target = producer || enterprise
    if product.variants?.length > 0
      prices = (variant.price for variant in product.variants)
      product.price = Math.min.apply(null, prices)
    product.primaryImage = product.image?.small_url if product.image
    product.primaryImageOrMissing = product.primaryImage || "/noimage/small.png"
    product.enterprise_name = target?.name || enterprise.name
    product.enterprise_path = target?.path || enterprise.path
    product.enterprise_id = target?.id || enterprise.id
    product

  $scope.addProducts = (enterprise, products) ->
    $scope.visibleProducts = $scope.visibleProducts.concat(products)

  $scope.applyEnterpriseFilters = (enterprises) ->
    filtered = $filter('closedShops')(enterprises, $scope.show_closed)
    filtered = $filter('taxons')(filtered, $scope.activeTaxons)
    filtered = $filter('properties')(filtered, $scope.activeProperties, 'distributed_properties')
    filtered = $filter('shipping')(filtered, $scope.shippingTypes)
    $filter('orderBy')(filtered, ['-active', '+distance', '+orders_close_at'])


  $scope.showDistanceMatches = ->
    $scope.distanceMatchesShown = true
    $scope.updateVisibleMatches()


  $scope.firstNameMatch = ->
    if $scope.nameMatchesFiltered? and $scope.nameMatchesFiltered.length > 0
      $scope.nameMatchesFiltered[0]
    else
      undefined

  $scope.showClosedShops = ->
    unless $scope.closed_shops_loaded
      $scope.closed_shops_loading = true
      $scope.closed_shops_loaded = true
      Enterprises.loadClosedEnterprises().then ->
        $scope.resetSearch($scope.query)

    $scope.show_closed = true
    $location.search('show_closed', '1')

  $scope.hideClosedShops = ->
    $scope.show_closed = false
    $location.search('show_closed', null)
