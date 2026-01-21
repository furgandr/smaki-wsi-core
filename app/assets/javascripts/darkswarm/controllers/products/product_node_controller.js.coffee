angular.module('Darkswarm').controller "ProductNodeCtrl", ($scope, $modal, $http, FilterSelectorsService) ->
  $scope.enterprise = $scope.product.supplier # For the modal, so it's consistent
  $scope.productPropertySelectors = FilterSelectorsService.createSelectors()

  if $scope.product?.recent_reviews?
    for review in $scope.product.recent_reviews
      review.rating_value = parseFloat((review.rating || 0).toString().replace(',', '.')) || 0
      review.rating = review.rating_value

  $scope.reviewRating = (review) ->
    parseFloat((review?.rating || 0).toString().replace(',', '.')) || 0

  $scope.triggerProductModal = ->
    $modal.open(templateUrl: "product_modal.html", scope: $scope)

  $scope.saveSellerResponse = (review) ->
    return unless review?.seller_can_reply

    csrf = document.querySelector('meta[name=csrf-token]')?.getAttribute('content')
    review._saving_response = true
    review._save_error = null
    $http.patch(
      "/api/v0/product_reviews/#{review.id}/response",
      product_review:
        seller_response: review.seller_response
    ,
      headers:
        "X-CSRF-Token": csrf
    ).then (response) ->
      review.seller_response = response.data.seller_response
      review._saving_response = false
    , (response) ->
      review._save_error = response.data?.error || "Save failed"
      review._saving_response = false
