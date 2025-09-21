import ballerina/grpc;
import ballerina/io;
import client.carrental;

public function main() returns error? {
    final carrental:CarRentalClient clientEp = check new ("http://localhost:9090");

    io:println("=== Adding a car ===");
    var addResp = check clientEp->add_car({ car: {
        make: "Toyota", model: "Corolla", year: 2022,
        daily_price: 50.0, mileage: 10000, plate: "ABC123", status: "AVAILABLE"
    }});
    io:println("Car added with plate: ", addResp.plate);

    io:println("=== Listing available cars ===");
    stream<carrental:Car, error?> res = check clientEp->list_available_cars({ filter: "" });
    record {}? val;
    while !(val is ()) {
        val = check res.next();
        if val is carrental:Car {
            io:println("Available: ", val.make, " ", val.model, " plate=", val.plate);
        }
    }

    io:println("=== Adding user (customer) via stream ===");
    stream<carrental:User, error?> ustrm = new;
    _ = check clientEp->create_users(ustrm);
    _ = ustrm.send({ id: "u1", name: "Alice", role: "CUSTOMER" });
    ustrm.complete();

    io:println("=== Add to cart ===");
    var cartResp = check clientEp->add_to_cart({
        user_id: "u1", plate: "ABC123", start_date: "2025-09-22", end_date: "2025-09-25"
    });
    io:println("Added to cart: ", cartResp.success.toString());

    io:println("=== Place reservation ===");
    var resResp = check clientEp->place_reservation({ user_id: "u1" });
    io:println("Reservation success: ", resResp.success.toString());
    foreach var r in resResp.reservations {
        io:println("Reserved ", r.plate, " for ", r.user_id);
    }

    io:println("=== List all reservations ===");
    var allRes = check clientEp->list_all_reservations({});
    foreach var r in allRes.reservations {
        io:println("Res: ", r.plate, " by ", r.user_id, " price=", r.price.toString());
    }
}
