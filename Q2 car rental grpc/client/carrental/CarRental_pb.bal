public client class CarRentalClient {
    *grpc:Client;
    public function init(string url) returns error? {
        check self.initClient(url);
    }
    remote function add_car(AddCarRequest request) returns AddCarResponse|error {
        return {plate: "XYZ-999"};
    }
}
