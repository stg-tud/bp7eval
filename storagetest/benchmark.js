offlineStorage = window.localStorage;
// LZW-compress a string
function lzw_encode(s) {
    var dict = {};
    var data = (s + "").split("");
    var out = [];
    var currChar;
    var phrase = data[0];
    var code = 256;
    for (var i = 1; i < data.length; i++) {
        currChar = data[i];
        if (dict[phrase + currChar] != null) {
            phrase += currChar;
        }
        else {
            out.push(phrase.length > 1 ? dict[phrase] : phrase.charCodeAt(0));
            dict[phrase + currChar] = code;
            code++;
            phrase = currChar;
        }
    }
    out.push(phrase.length > 1 ? dict[phrase] : phrase.charCodeAt(0));
    for (var i = 0; i < out.length; i++) {
        out[i] = String.fromCharCode(out[i]);
    }
    return out.join("");
}

// Decompress an LZW-encoded string
function lzw_decode(s) {
    var dict = {};
    var data = (s + "").split("");
    var currChar = data[0];
    var oldPhrase = currChar;
    var out = [currChar];
    var code = 256;
    var phrase;
    for (var i = 1; i < data.length; i++) {
        var currCode = data[i].charCodeAt(0);
        if (currCode < 256) {
            phrase = data[i];
        }
        else {
            phrase = dict[currCode] ? dict[currCode] : (oldPhrase + currChar);
        }
        out.push(phrase);
        currChar = phrase.charAt(0);
        dict[code] = oldPhrase + currChar;
        code++;
        oldPhrase = phrase;
    }
    return out.join("");
}

function toHexString(byteArray) {
    return Array.from(byteArray, function (byte) {
        return ('0' + (byte & 0xFF).toString(16)).slice(-2);
    }).join('')
}
// Convert a hex string to a byte array
function hexToBytes(hexString) {
    var result = [];
    while (hexString.length >= 2) {
        result.push(parseInt(hexString.substring(0, 2), 16));
        hexString = hexString.substring(2, hexString.length);
    }
    return result;
}

function stringFromArray(data) {
    var count = data.length;
    var str = "";

    for (var index = 0; index < count; index += 1)
        str += String.fromCharCode(data[index]);

    return str;
}

function stringToAsciiByteArray(str) {
    var bytes = [];
    for (var i = 0; i < str.length; ++i) {
        var charCode = str.charCodeAt(i);
        if (charCode > 0xFF)  // char > 1 byte since charCodeAt returns the UTF-16 value
        {
            throw new Error('Character ' + String.fromCharCode(charCode) + ' can\'t be represented by a US-ASCII byte.');
        }
        bytes.push(charCode);
    }
    return bytes;
}
function storageAvailable(type) {
    var storage;
    try {
        storage = window[type];
        var x = '__storage_test__';
        storage.setItem(x, x);
        storage.removeItem(x);
        return true;
    }
    catch (e) {
        return e instanceof DOMException && (
            // everything except Firefox
            e.code === 22 ||
            // Firefox
            e.code === 1014 ||
            // test name field too, because code might not be present
            // everything except Firefox
            e.name === 'QuotaExceededError' ||
            // Firefox
            e.name === 'NS_ERROR_DOM_QUOTA_REACHED') &&
            // acknowledge QuotaExceededError only if there's something already stored
            (storage && storage.length !== 0);
    }
}

function insert_rnd_bundle() {
    Rust.bp7.then(function (bp7) {
        var b = bp7.rnd_bundle_now();
        var bid = bp7.bid_from_bundle(b);
        console.log('inserting random bundle: ', bid);
        store[bid] = bp7.encode_to_cbor(b);
    });
}
function load_bundles() {
    var raw_load = offlineStorage.getItem('bundles');
    if (raw_load == null) return {};


    var lzbundles = LZString.decompress(raw_load);
    //console.log("raw: ", JSON.parse(raw_load));

    if (lzbundles == null) {
        console.log("plain bundles stored ");
        return JSON.parse(raw_load);
    } else {
        console.log("compressed bundles stored");
        return JSON.parse(lzbundles);
    }
}
var startTime, endTime;
function start_measurement() {
    startTime = new Date();
};

var lastMs = 0;

function end_measurement() {
    endTime = new Date();
    var timeDiff = endTime - startTime; //in ms
    // strip the ms
    //timeDiff /= 1000.0;

    // get seconds 
    lastMs = Math.round(timeDiff);
    console.log(lastMs + " ms");
}

function save_offline_plain() {
    if (storageAvailable('localStorage')) {
        console.log("saving store - start");
        start_measurement();
        offlineStorage.setItem('bundles', JSON.stringify(store));
        end_measurement();
        console.log("saving store - stop");
    }
    else {
        // Too bad, no localStorage for us
        console.log("FATAL: local storage full! " + offlineStorage.length + " " + Object.keys(load_bundles()).length);
    }
}


function save_offline_lz() {
    if (storageAvailable('localStorage')) {
        // Yippee! We can use localStorage awesomeness
        //offlineStorage.setItem('bundles', JSON.stringify(store));
        console.log("compressing store - start");
        start_measurement();
        offlineStorage.setItem('bundles', LZString.compress(JSON.stringify(store)));
        //offlineStorage.setItem('bundles', lzw_encode(JSON.stringify(store)));
        end_measurement();
        console.log("compressing store - stop");
    }
    else {
        // Too bad, no localStorage for us
        console.log("FATAL: local storage full! " + offlineStorage.length + " " + Object.keys(load_bundles()).length);
    }
}


function flood_storage(steps = 1000, timeout = 30000) {
    //while (storageAvailable('localStorage')) {
    Rust.bp7.then(function (bp7) {
        try {
            while (true) {
                console.log("generating bundles");
                for (var i = 0; i < steps; i++) {
                    var b = bp7.rnd_bundle_now();
                    var bid = bp7.bid_from_bundle(b);
                    //console.log('inserting random bundle: ', bid);
                    store[bid] = bp7.encode_to_cbor(b);
                }
                window.save_off();
                console.log("#msgs in store: ", Object.keys(store).length + " @ " + lastMs + " ms");
                if (lastMs > timeout) break;
            }
        } catch (error) {
            console.log("flood loop error");
        }
        storage_stats();
        console.log("end storage flood");
    });
}
function storage_stats() {
    console.log("local storage: " + offlineStorage.length
        + " " + offlineStorage.getItem('bundles').length
        + " " + Object.keys(load_bundles()).length
        + " " + lastMs + " ms");
}

function load_offline() {
    console.log("decompressing store - start");
    store = load_bundles();
    console.log("decompressing store - stop");

    console.log(store);
}

var store = {};
//refresh_bundles();

window.save_off = save_offline_plain;

function bench_storage_plain() {
    console.log("benchmark - plain");
    store = {};
    window.save_off = save_offline_plain;
    window.save_off();
    flood_storage(100);
}

function bench_storage_compressed() {
    console.log("benchmark - compressed");
    store = {};
    window.save_off = save_offline_lz;
    window.save_off();
    flood_storage(10000);
}