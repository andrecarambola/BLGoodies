//** BLGoodies **//
//* Push *//

//Functions

/*
SEND PUSH TO USERS

* Params
userIds: recipient users' object id
pushData: the data object to be sent

* Response
Value: a string indicating an error or success

*/

/*
SEND PUSH TO CHANNELS

* Params
channels: the channels to be targeted
pushData: the data object to be sent

* Response
Value: a string indicating an error or success

*/


//* CODE *//

//Variables
var globalResponse;
var userIds;
var channels;
var pushData;
var fetchedUser;


//Sending Push

function SendPushToQuery(query)
{
    if (!query) {
        globalResponse.error("no query");
    } else {
        Parse.Push.send({
            where: query,
            data: pushData
        }).then(function() {
            globalResponse.success(true);
        }, function(error) {
            globalResponse.error(error);
        });
    }
}

function CreateQuery(toUser)
{
    var result = new Parse.Query(Parse.Installation);
    if (toUser == true) {
        var users = [];
        for (var i=0; i<userIds.length; ++i) {
            var tempUser = new Parse.User();
            tempUser.id = userIds[i];
            users.push(tempUser);
        }
        result.containedIn("user",users);
    } else {
        result.containedIn("channels",channels);
    }
    return result;
}

//Validating Push Data

function ValidateData(callback)
{
    var tempAlert = pushData["alert"];
    if (tempAlert.length == 0) {
        globalResponse.error("no message");
    } else {
        if (tempAlert.length > 140) {
            tempAlert = tempAlert.substring(0, 137) + "...";
            pushData["alert"] = tempAlert;
        }
        callback();
    }
}

//Validating User

function CanSendPush(callback)
{
    var roleQuery = new Parse.Query(Parse.Role);
    roleQuery.equalTo("users",fetchedUser);
    roleQuery.count({
        success: function(count) {
            if (count >= 1) {
                callback();
            } else {
                globalResponse.error("count error");
            }
        },
        error: function(error) {
            globalResponse.error("query error");
        }
    });
}


//Parse
Parse.Cloud.define("sendPushToUsers", function(request, response) 
{
	var user = request.user;
	if (!user || !user.authenticated()) {
		console.log("an error");
		response.error("an error");
	} else {
		userIds = request.params["userIds"];
		pushData = request.params["pushData"];
		if (userIds && userIds.length > 0 && pushData) {
		    globalResponse = response;
            ValidateData(function() {
                var query = CreateQuery(true);
                SendPushToQuery(query);
            });
		} else {
			response.error("another error");
		}
	}
});

Parse.Cloud.define("sendPushToChannels", function(request, response) 
{
	var user = request.user;
	if (!user || !user.authenticated()) {
		console.log("an error");
		response.error("an error");
	} else {
		channels = request.params["channels"];
		pushData = request.params["pushData"];
		if (channels && channels.length > 0 && pushData) {
		    globalResponse = response;
		    fetchedUser = user;
            ValidateData(function() {
                CanSendPush(function() {
                    var query = CreateQuery(false);
                    SendPushToQuery(query);
                });
            });
		} else {
			response.error("another error");
		}
	}
});
