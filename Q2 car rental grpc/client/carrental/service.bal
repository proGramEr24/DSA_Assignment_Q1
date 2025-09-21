module carrental;

import ballerina/grpc;

public client class CarRentalClient {
    *grpc:Client;

    remote function AddCar(AddCarRequest value) returns AddCarResponse|error {}
    remote function CreateUsers(stream<User, error?> value) returns CreateUsersResponse|error {}
    remote function UpdateCar(UpdateCarRequest value) returns UpdateCarResponse|error {}
    remote function RemoveCar(RemoveCarRequest value) returns RemoveCarResponse|error {}
    remote function ListAvailableCars(ListAvailableRequest value) returns stream<Car, error?>|error {}
    remote function SearchCar(SearchCarRequest value) returns SearchCarResponse|error {}
    remote function AddToCart(AddToCartRequest value) returns AddToCartResponse|error {}
    remote function PlaceReservation(PlaceReservationRequest value) returns PlaceReservationResponse|error {}
    remote function ListAllReservations(ListAllReservationsRequest value) returns ListAllReservationsResponse|error {}
};

public service interface CarRental {
    remote function AddCar(AddCarRequest value) returns AddCarResponse;
    remote function CreateUsers(stream<User, error?> value) returns CreateUsersResponse;
    remote function UpdateCar(UpdateCarRequest value) returns UpdateCarResponse;
    remote function RemoveCar(RemoveCarRequest value) returns RemoveCarResponse;
    remote function ListAvailableCars(ListAvailableRequest value) returns stream<Car, error?>;
    remote function SearchCar(SearchCarRequest value) returns SearchCarResponse;
    remote function AddToCart(AddToCartRequest value) returns AddToCartResponse;
    remote function PlaceReservation(PlaceReservationRequest value) returns PlaceReservationResponse;
    remote function ListAllReservations(ListAllReservationsRequest value) returns ListAllReservationsResponse;
};
