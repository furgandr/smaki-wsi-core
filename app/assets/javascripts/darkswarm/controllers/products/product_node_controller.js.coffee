angular.module('Darkswarm').controller "ProductNodeCtrl", ($scope, $modal, $http, FilterSelectorsService) ->
  $scope.enterprise = $scope.product.supplier # For the modal, so it's consistent
  $scope.productPropertySelectors = FilterSelectorsService.createSelectors()

  $scope.triggerProductModal = ->
    $modal.open(templateUrl: "product_modal.html", scope: $scope)

  $scope.saveSellerResponse = (review) ->
    return unless review?.seller_can_reply

    review._saving_response = true
    $http.patch(
      "/api/v0/product_reviews/#{review.id}/response",
      product_review:
        seller_response: review.seller_response
    ).then (response) ->
      review.seller_response = response.data.seller_response
      review._saving_response = false
    , ->
      review._saving_response = false
