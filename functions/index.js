"use strict";

const functions = require("firebase-functions");

const distance_threshold = 0.01;

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
admin.initializeApp();
    
exports.kaitakaroCoordinate = functions.database.ref('/games/{gameId}/kaitakaro/{kaitakaroId}/coordinate')
.onWrite(async(coordinateSnapshot, context) => {
    const coordinateSnapshotAfter = coordinateSnapshot.after
    const kaitakaroCoordinate = coordinateSnapshotAfter.val();
    const kaitakaroRef = coordinateSnapshotAfter.ref.parent;
    // const kaitakaroSnapshot = kaitakaroRef.get();
    var kaitakaroSnapshot;
    const kapaPath = 'games/' + context.params.gameId + '/kapa';

    kaitakaroRef.once('value').then(function(kSnapshot) {
        kaitakaroSnapshot = kSnapshot;
        functions.logger.log('kaitakaroSnapshot: ' + kaitakaroSnapshot.exportVal());
        functions.logger.log('name: ' + kaitakaroSnapshot.child('display_name').val());
        functions.logger.log('title: ' + kaitakaroSnapshot.child('character/title').val());
    
        // get all the kapa for this game
        const ngaKapa = admin.database().ref(kapaPath).once('value').then(function(ngaKapaSnapshot) {
            functions.logger.log('ngaKapaSnapshot');
            functions.logger.log(ngaKapaSnapshot.exportVal());
            var foundKapaRef = null;

            // check how many kapa there are
            
            // Iterate through all kapa, checking for proximity
            ngaKapaSnapshot.forEach(function(kapaSnapshot) {
                var kapaCoordinate = kapaSnapshot.child('coordinate').val();
                
                var dist = calcCrow(kaitakaroCoordinate.latitude, kaitakaroCoordinate.longitude, kapaCoordinate.latitude, kapaCoordinate.longitude);
                functions.logger.log(dist);

                if (dist < distance_threshold) {
                    functions.logger.log("2 CLOSE ENOUGH!!!");
                    
                    foundKapaRef = kapaSnapshot.ref;

                    kapaSnapshot.ref.child('kaitakaro/' + kaitakaroRef.key).set(
                        {
                            coordinate: kaitakaroCoordinate,
                            display_name: kaitakaroSnapshot.child('display_name').val(),
                            character: kaitakaroSnapshot.child('character/title').val()
                        }
                    ).then(function() {
                    // kapaSnapshot.ref.child('kaitakaro/' + kaitakaroRef.key + '/coordinate').set(kaitakaroCoordinate).then(function() {
                        functions.logger.log('Synchronization succeeded');
                        
                        // set the kapa of the kaitakaro
                        kaitakaroRef.child('kapa').set(
                            {
                                kapa_key: kapaSnapshot.key
                            }
                        );
                    })
                    .catch(function(error) {
                        functions.logger.log('Synchronization failed');
                    });
                } else {
                    functions.logger.log('Too far');
                }
            });
            
            functions.logger.log('foundKapaRef: ' + foundKapaRef);
            functions.logger.log('numChildren: ' + ngaKapaSnapshot.numChildren());

            // check how many kapa there are
            if (foundKapaRef == null && ngaKapaSnapshot.numChildren()<2)
            {
                functions.logger.log('Creating new kapa');
                var newKapaRef = ngaKapaSnapshot.ref.push();
                newKapaRef.ref.child('kaitakaro/' + kaitakaroRef.key).set(
                    {
                        coordinate: kaitakaroCoordinate,
                        display_name: kaitakaroSnapshot.child('display_name').val(),
                        character: kaitakaroSnapshot.child('character/title').val()
                    }
                ).then(function() {
                    functions.logger.log('New Kapa synchronization succeeded');
                    
                    // set the kapa of the kaitakaro
                    kaitakaroRef.child('kapa').set(
                        {
                            kapa_key: newKapaRef.key
                        }
                    );
                })
                .catch(function(error) {
                    functions.logger.log('New kapa synchronization failed');
                });
            }

            // check if we've left a kapa
            kaitakaroRef.once('value').then(function(kaitakaroSnapshot) {
                const hasChild = kaitakaroSnapshot.hasChild('kapa');
                functions.logger.log('hasChild: ' + hasChild);
                if (foundKapaRef == null && hasChild == true)
                {
                    functions.logger.log('NO KAPA FOUND AND HAS KAPA');
                    // we now need to remove the kaitakaro from the kapa
                    admin.database().ref(kapaPath).child(kaitakaroSnapshot.child('kapa/kapa_key').val()).child('kaitakaro').child(kaitakaroSnapshot.key).remove()
                        .then(function(kapaSnapshot) {
                            functions.logger.log("Kapa remove succeeded.");
                        })
                        .catch(function(error) {
                            functions.logger.log("Kapa remove failed: " + error.message);
                        });

                    // and remove the kapa from the kaitakaro
                    kaitakaroRef.child('kapa').remove()
                        .then(function() {
                            functions.logger.log("Remove succeeded.");
                        })
                        .catch(function(error) {
                            functions.logger.log("Remove failed: " + error.message);
                        });
                }
            });
        });
    });
});
    
exports.kapaCoordinate = functions.database.ref('/games/{gameId}/kapa/{kapaId}/kaitakaro/{kaitakaroId}/coordinate')
    .onWrite(async(coordinateSnapshot, context) => {
        functions.logger.log('Kapa kaitakaro coordinate update');
        const kapaRef = coordinateSnapshot.after.ref.parent.parent.parent;
        
        var new_lat = 0;
        var new_long = 0;
        
        const kapaSnapshot = kapaRef.once('value').then(function(dataSnapshot) {
            const ngaKaitakaro = dataSnapshot.child('kaitakaro');
            const numChildren = ngaKaitakaro.numChildren();
            ngaKaitakaro.forEach(function(kaitakaroSnapshot) {
                const coordinate = kaitakaroSnapshot.child('coordinate').val();
                new_lat += coordinate.latitude;
                new_long += coordinate.longitude;
            });
            
            new_lat /= numChildren;
            new_long /= numChildren;
            
            kapaRef.child('coordinate').set(
                {
                    latitude: new_lat, 
                    longitude: new_long
                }
            ).then(function() {
                functions.logger.log('Synchronization succeeded');
            })
            .catch(function(error) {
                functions.logger.log('Synchronization failed');
            });
        });
    });

//This function takes in latitude and longitude of two location and returns the distance between them as the crow flies (in km)
function calcCrow(lat1, lon1, lat2, lon2) 
{
  var R = 6371; // km
  var dLat = toRad(lat2-lat1);
  var dLon = toRad(lon2-lon1);
  var lat1 = toRad(lat1);
  var lat2 = toRad(lat2);

  var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2); 
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  var d = R * c;
  return d;
}

// Converts numeric degrees to radians
function toRad(Value) 
{
    return Value * Math.PI / 180;
}
