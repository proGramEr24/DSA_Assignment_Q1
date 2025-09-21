import ballerina/io;
import ballerina/http;

// ==== Data Models ====
type Component record {
    string id?;
    string name?;
    string description?;
};

type Schedule record {
    string id?;
    string frequency?;
    string nextDueDate?;
};

type Task record {
    string id?;
    string description?;
    string status?;
};

type WorkOrder record {
    string id?;
    string description?;
    string status?;
    Task[] tasks?;
};

type Asset record {
    string assetTag?;
    string name?;
    string faculty?;
    string department?;
    string status?;
    string acquiredDate?;
    Component[] components?;
    Schedule[] schedules?;
    WorkOrder[] workOrders?;
};

// ==== Main ====
public function main() returns error? {
    http:Client assetClient = check new ("http://localhost:8080/assets");

    io:println("1. Create Asset");
    io:println("2. Add Component");
    io:println("3. Add Schedule");
    io:println("4. Add Work Order");
    io:println("5. Add Task under Work Order");
    io:println("6. View Asset By Faculty");
    io:println("7. View All Assets");

    string option = io:readln("Choose an option: ");

    match option {
        "1" => {
            Asset asset = {};
            asset.assetTag = io:readln("Enter Asset Tag: ");
            asset.name = io:readln("Enter Asset Name: ");
            asset.faculty = io:readln("Enter Faculty: ");
            asset.department = io:readln("Enter Department: ");
            asset.status = io:readln("Enter Status (ACTIVE/UNDER_REPAIR/DISPOSED): ");
            asset.acquiredDate = io:readln("Enter Acquired Date (YYYY-MM-DD): ");
            asset.components = [];
            asset.schedules = [];
            asset.workOrders = [];
            check createAsset(assetClient, asset);
        }
        "2" => {
            string tag = io:readln("Enter Asset Tag: ");
            Component comp = {};
            comp.id = io:readln("Enter Component ID: ");
            comp.name = io:readln("Enter Component Name: ");
            comp.description = io:readln("Enter Component Description: ");
            check addComponent(assetClient, tag, comp);
        }
        "3" => {
            string tag = io:readln("Enter Asset Tag: ");
            Schedule sched = {};
            sched.id = io:readln("Enter Schedule ID: ");
            sched.frequency = io:readln("Enter Frequency (e.g., Quarterly): ");
            sched.nextDueDate = io:readln("Enter Next Due Date (YYYY-MM-DD): ");
            check addSchedule(assetClient, tag, sched);
        }
        "4" => {
            string tag = io:readln("Enter Asset Tag: ");
            WorkOrder wo = {};
            wo.id = io:readln("Enter Work Order ID: ");
            wo.description = io:readln("Enter Work Order Description: ");
            wo.status = io:readln("Enter Status (OPEN/IN_PROGRESS/CLOSED): ");
            wo.tasks = [];
            check addWorkOrder(assetClient, tag, wo);
        }
        "5" => {
            string tag = io:readln("Enter Asset Tag: ");
            string woId = io:readln("Enter Work Order ID: ");
            Task task = {};
            task.id = io:readln("Enter Task ID: ");
            task.description = io:readln("Enter Task Description: ");
            task.status = io:readln("Enter Task Status (OPEN/DONE): ");
            check addTask(assetClient, tag, woId, task);
        }
        "6" => {
            string tag = io:readln("Enter Asset Faculty: ");
            check getAssetByFaculty(assetClient, tag);
        }
        "7" => {
            check getAllAssets(assetClient);
        }
        _ => {
            io:println("Invalid Option");
            check main();
        }
    }
}


public function createAsset(http:Client client, Asset asset) returns error? {
    json message = check client->post("/", asset);
    io:println("Response: ", message.toJsonString());
}

public function addComponent(http:Client client, string tag, Component comp) returns error? {
    json message = check client->post("/" + tag + "/components", comp);
    io:println("Response: ", message.toJsonString());
}

public function addSchedule(http:Client client, string tag, Schedule sched) returns error? {
    json message = check client->post("/" + tag + "/schedules", sched);
    io:println("Response: ", message.toJsonString());
}

public function addWorkOrder(http:Client client, string tag, WorkOrder wo) returns error? {
    json message = check client->post("/" + tag + "/workorders", wo);
    io:println("Response: ", message.toJsonString());
}

public function addTask(http:Client client, string tag, string woId, Task task) returns error? {
    json message = check client->post("/" + tag + "/workorders/" + woId + "/tasks", task);
    io:println("Response: ", message.toJsonString());
}

public function getAssetByFaculty(http:Client client, string tag) returns error? {
    Asset asset = check client->get("/" + tag);
    io:println("---- Asset ----");
    io:println("Tag: ", asset.assetTag);
    io:println("Name: ", asset.name);
    io:println("Faculty: ", asset.faculty);
    io:println("Department: ", asset.department);
    io:println("Status: ", asset.status);
    io:println("Acquired: ", asset.acquiredDate);
    io:println("Components: ", asset.components);
    io:println("Schedules: ", asset.schedules);
    io:println("Work Orders: ", asset.workOrders);
}

public function getAllAssets(http:Client client) returns error? {
    Asset[] assets = check client->get("/");
    foreach var a in assets {
        io:println("---- Asset ----");
        io:println("Tag: ", a.assetTag);
        io:println("Name: ", a.name);
        io:println("Faculty: ", a.faculty);
        io:println("Department: ", a.department);
        io:println("Status: ", a.status);
    }
}
