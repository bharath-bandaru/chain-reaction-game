// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getAuth, signInAnonymously, onAuthStateChanged } from "firebase/auth";
import { getDatabase, onDisconnect, ref, set } from "firebase/database";


const firebaseConfig = {
    apiKey: "AIzaSyCwTUxZUqK89uapKCbMMbMHXk2eU-NsKq0",
    authDomain: "chain-reaction-18013.firebaseapp.com",
    databaseURL: "https://chain-reaction-18013-default-rtdb.firebaseio.com",
    projectId: "chain-reaction-18013",
    storageBucket: "chain-reaction-18013.appspot.com",
    messagingSenderId: "626865732219",
    appId: "1:626865732219:web:287a045ff6b6711b3100de",
    measurementId: "G-YW168Y2371"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const analytics = getAnalytics(app);
export const auth = getAuth(app);
export const database = getDatabase(app);
export var localuser = null;
export var playerRef = null;


onAuthStateChanged(auth, (user) => {
    if (user) {
        console.log(user);
        localuser = user;
        playerRef = ref(database, 'players/' + user.uid);
        set(playerRef, {
            id: true,
        });
        onDisconnect(playerRef).set(false);
    } else {
        console.log('User is signed out');
    }
});

export const getUser = () => {
    return localuser;
}

export const signIn = () => {
    signInAnonymously(auth)
        .then(() => {
            // Signed in..
            console.log('User is signed in Anonymously');
        })
        .catch((error) => {
            // ...
        });
}


export const generateGroupIds = (user) => {
    var uniqs = new Set();
    var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var charactersLength = characters.length;

    for (var j = 0; j < 10000; j++) {
        var result = ""
        for (var i = 0; i < 4; i++) {
            result += characters.charAt(Math.floor(Math.random() * charactersLength));
        }
        uniqs.add(result);
    }
    for (const each of uniqs) {
        set(ref(database, 'groups/' + each), {emp:"val"})
            .then(() => {
                console.log("Data saved successfully!");
            })
            .catch((error) => {
                // The write failed...
            });
    }
    console.log(uniqs);

}