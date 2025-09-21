import ballerina/http;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/task;
import ballerina/time;

enum CurrentStatus {
    Active,
    Under_repair,
    Disposed
}

type Asset record {
    readonly string assetTag;
    string name;
    string faculty;
    string department;
    CurrentStatus status; //enum
    string acquiredDate;
    Component components;
    Schedule schedules;
    WorkOrder workOrders;
    Task task;
};

type Component record {
    readonly string PartName;
    string ComponentDescription;  
};

type Schedule record {
    string scheduleDescription;
    readonly string nextDueDate;
};

type WorkOrder record {
    readonly string workOrderId;
    string WorkOrderDescription;
    string CurrentStatus;
};

type Task record {
    readonly string taskId;
    string TaskDescription;
};

table<Asset> key(assetTag) assets = table [];
table<Component> key(PartName) component = table[];
table<WorkOrder> key(workOrderId) workOrder = table[];
table<Schedule> key(nextDueDate) schedule = table[];
table<Task> key(taskId) task = table[];

// Creates a asset to be executed by the scheduler.
class Assetschedule {
    *task:Job;
    int i = 1;

    // Executes this function when the scheduled trigger fires.
    public function execute() {
        self.i += 1;
        io:println("Asset schedule: ", self.i);
    }
}

public function main() returns error? {
    //Gets the current time.
    time:Utc currentUtc = time:utcNow();
    // Increases the time by three seconds to get the specified time for scheduling the job.
    time:Utc newTime = time:utcAddSeconds(currentUtc, 3);
    // Gets the `time:Civil` for the given time.
    time:Civil time = time:utcToCivil(newTime);

    // Schedules the one-time job at the specified time.
    _ = check task:scheduleOneTimeJob(new Job(0), time);

    // Waits for three seconds.
    runtime:sleep(3);
}


service / on new http:Listener(9090) {

//Create asset
    resource function post createAsset(Asset newAsset) returns string|error {
       error? createNewAsset = assets.add(newAsset);

       if (createNewAsset is error){
        return "Error" + createNewAsset.message();
       }else {
        return newAsset.name + "successfully added";
       }
    }
    
// Get all assets
    resource function get viewAssets() returns table<Asset> key(assetTag) {
        return assets;
    }
    
// View assets by Faculty
    resource function get getAssetByFaculty(string assetTag) returns Asset|string {
        foreach Asset facultyAsset in assets {
            if (facultyAsset.assetTag === assetTag) {
                return facultyAsset;
            }
        }

        return assetTag + "does not exist";
    }


    resource function get overdue() returns Asset[] {
       string today = runtime:getDateTime().toString().substring(0,10);
        return from var a in assets
            where a.schedules.some(s => s.nextDueDate < today)
           select a;
    }

// Update asset
    resource function put updateAsset(Asset updatedAsset) returns string|error {
        error? updateAsset = assets.put(updatedAsset);

        if (updateAsset is error){
            return "Error" + updateAsset.message();
        }else {
            return updatedAsset.name + "successfully updated";
        }
    }

// View all 
    resource function get [string assetTag]() returns Asset|error {
        if assets.hasKey(assetTag) {
            return assets[assetTag] ?: {};
       }
       return error("Asset not found.");
    }

//Delete asset
    resource function delete deleteAsset/[string assetTag]() returns string|error {
        Asset|error deleteAsset = assets.remove(assetTag);

        if (deleteAsset is error) {
            return "Error" + deleteAsset.message();
        }else {
            return deleteAsset.name + "deleted successfully";
        }
    }


//Add components
    resource function post createComponent(Component newComponent) returns string|error{
        error? createComponent = component.add(newComponent);
        if createComponent is error {
            return error("Failed to add new component");
        }
        return newComponent.PartName + "created successfully.";
    }

//Remove component
    resource function delete deleteComponent/[string component]() returns string {
        Component|error deleteComponent = component.remove();

        if (deleteComponent is error) {
            return "Error" + deleteComponent.message();
        }else {
            return deleteComponent.PartName + "deleted successfully";
        }
        
    }

//Manage schedules
   resource function post [string assetTag]/schedules(Schedule schedule) returns json {
       if assets.hasKey(assetTag) {
            assets[assetTag]!.schedules.push(schedule);
            return {message: "Schedule successfully added."};
        }
        return {message: "Asset not found."};
   }

//Manage work orders
   resource function post [string assetTag]/WorkOrder(WorkOrder w) returns json {
      if assets.hasKey(assetTag) {
           assets[assetTag].workOrders.push(w);
            return {message: "Work order successfully added."};
        }
       return {message: "Asset not found."};
    }

//Manage tasks under a work order
   resource function post [string assetTag]/workorders/[string workorderId]/tasks(Task task)returns json {
        if assets.hasKey(assetTag) {
            foreach var wo in assets[assetTag].workOrders {
               if wo.workOrderId == workorderId {
                    wo.tasks.push(task);
                    return {message: "Task successfully added."};
                }
           }
           return {message: "Work order not found."};
       }
       return {message: "Asset not found."};
    }
}
