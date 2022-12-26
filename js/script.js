
// Write the alphabet from lower to upper case
let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
let alphabet_len = alphabet.length;

let websocket = new WebSocket("wss://clouddata.turbowarp.org/", ["User-Agent"]);

websocket.onerror = (event) => {
    console.log("Websocket error");
    console.log(event);
}

let input_data = document.getElementById("input-data"), send_button = document.getElementById("send-button"), project_id_used = document.getElementById("project-id-used");

const project_id = 777954330;

websocket.onopen = (event) => {
    console.log("Connection open");
    console.log(event);

    project_id_used.innerHTML += '<a style="text-decoration: none;" href="https://turbowarp.org/'+ project_id +'" target="_blank"><code id="project-id" style="background-color:rgb(224, 224, 224); color: rgb(31, 18, 18);">turbowarp.org/'+ project_id +'</code></a>';

    /// Handshake request \
    websocket.send(JSON.stringify({ "method": "handshake", "user": "nikeedev", "project_id": project_id }));
    /// Handshake request /


    setTimeout(function() {
        websocket.send(JSON.stringify({ "method": "set", "project_id": project_id, "user": "nikeedev", "name": "☁ cloud", "value": 7 }));
    }, 500);

    
    setInterval(() => {
        send_button.onclick = (event) => {
            websocket.send(JSON.stringify({ "method": "set", "project_id": project_id, "user": "nikeedev", "name": "☁ cloud", "value": input_data.value }));
            console.log("Value " + input_data.value + " sent");
        }
    }, 1000);
    

    console.log("Sent the message");

}

websocket.onmessage = (event) => {
    console.log(event);
    
    setInterval(() => {
        console.log("Receiving messages:", event.data);
    }, 1000);
}

websocket.onclose = (event) => {
    console.log(event);
    console.log("Closed connection")
}
