import ballerina/grpc;
import ballerina/log;
import server.carrental;
import carrental_pb as carrental;

type CartItem record {
    string plate;
    string start_date;
    string end_date;
};

final map<carrental:Car> cars = {};
final map<carrental:User> users = {};
final map<CartItem[]> carts = {};
final carrental:Reservation[] reservations = [];

service class CarRentalService {
    *carrental:CarRental;

    isolated function add_car(carrental:AddCarRequest request)
            returns carrental:AddCarResponse|error {
        cars[request.car.plate] = request.car;
        log:printInfo("Car added: " + request.car.plate);
        return { plate: request.car.plate };
    }

    isolated function create_users(stream<carrental:User, error?> clientStream)
            returns carrental:CreateUsersResponse|error {
        int count = 0;
        record {}? val;
        while !(val is ()) {
            val = check clientStream.next();
            if val is carrental:User {
                users[val.id] = val;
                count += 1;
            }
        }
        return { count };
    }

    isolated function update_car(carrental:UpdateCarRequest request)
            returns carrental:UpdateCarResponse|error {
        if cars.hasKey(request.plate) {
            cars[request.plate] = request.car;
            return { success: true };
        }
        return { success: false };
    }

    isolated function remove_car(carrental:RemoveCarRequest request)
            returns carrental:RemoveCarResponse|error {
        if cars.hasKey(request.plate) {
            cars.remove(request.plate);
        }
        return { cars: cars.values().toArray() };
    }

    isolated function list_available_cars(carrental:ListAvailableRequest request)
            returns stream<carrental:Car, error?> {
        stream<carrental:Car, error?> strm = new;
        foreach var [_, car] in cars.entries() {
            if car.status == "AVAILABLE" &&
               (request.filter == "" || car.make.contains(request.filter) || car.model.contains(request.filter)) {
                strm.send(car);
            }
        }
        strm.complete();
        return strm;
    }

    isolated function search_car(carrental:SearchCarRequest request)
            returns carrental:SearchCarResponse|error {
        if cars.hasKey(request.plate) {
            return { available: cars[request.plate].status == "AVAILABLE",
                     car: cars[request.plate] };
        }
        return { available: false };
    }

    isolated function add_to_cart(carrental:AddToCartRequest request)
            returns carrental:AddToCartResponse|error {
        if !cars.hasKey(request.plate) {
            return { success: false };
        }
        CartItem item = { plate: request.plate,
                          start_date: request.start_date,
                          end_date: request.end_date };
        if !carts.hasKey(request.user_id) {
            carts[request.user_id] = [];
        }
        carts[request.user_id].push(item);
        return { success: true };
    }

    isolated function place_reservation(carrental:PlaceReservationRequest request)
            returns carrental:PlaceReservationResponse|error {
        if !carts.hasKey(request.user_id) {
            return { success: false, reservations: [] };
        }
        carrental:Reservation[] confirmed = [];
        foreach var item in carts[request.user_id] {
            if cars.hasKey(item.plate) && cars[item.plate].status == "AVAILABLE" {
                float price = 1.0 * cars[item.plate].daily_price;
                carrental:Reservation r = {
                    user_id: request.user_id,
                    plate: item.plate,
                    start_date: item.start_date,
                    end_date: item.end_date,
                    price: price
                };
                reservations.push(r);
                confirmed.push(r);
                cars[item.plate].status = "UNAVAILABLE";
            }
        }
        carts.remove(request.user_id);
        return { success: confirmed.length() > 0, reservations: confirmed };
    }

    isolated function list_all_reservations(carrental:ListAllReservationsRequest request)
            returns carrental:ListAllReservationsResponse|error {
        return { reservations };
    }
}

listener grpc:Listener ep = new (9090);
service /CarRental on ep = new CarRentalService();
