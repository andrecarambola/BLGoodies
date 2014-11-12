//** BLGoodies **//
//* New User *//

//Functions

/*
UPDATE NEW USER

* Params
userId: the new user's object id

* Response
Value: a string indicating an error or success

*/


//* CODE *//

//Variables
var globalResponse;
var clientRole;
var fetchedUser;


//Finding and adding user to the Client Role

function AddUserToRole(aRole)
{
	aRole.getUsers().add(fetchedUser);
	aRole.save(null, {
		success: function(tempRole) {
			globalResponse.success(true);
		},
		error: function(aRole, error) {
			console.log(error);
			globalResponse.error("couldn't save role");
		}
	});
}

function FindClientRole(callback)
{
	var roleQuery = new Parse.Query(Parse.Role);
	roleQuery.equalTo("name","Client");
	roleQuery.find({
		success: function(results) {
			if (results.length>0) {
				callback(results[0]);
			} else {
				globalResponse.error("couldn't get role");
			}
		},
		error: function(error) {
			console.log(error);
			globalResponse.error("couldn't get role");
		}
	});
}

//Parse
Parse.Cloud.define("updateNewUser", function(request, response) 
{
	var user = request.user;
	if (!user || !user.authenticated()) {
		console.log("an error");
		response.error("an error");
	} else {
		var tempUserID = request.params["userId"];
		if (tempUserID && tempUserID.length > 0) {
			globalResponse = response;
			fetchedUser = user;
			Parse.Cloud.useMasterKey();
			FindClientRole(function(aRole) {
    			AddUserToRole(aRole);
			});
		} else {
			response.error("another error");
		}
	}
});