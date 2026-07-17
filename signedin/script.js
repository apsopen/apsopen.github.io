let password = sessionStorage.getItem("clientPassword");

if (!password) {
    window.location.href = "/";
}


async function loadPackages() {

    const response = await fetch("data.json");
    const json = await response.json();

    const packages = document.getElementById("packages");
    const tools = document.getElementById("tools");


    json.data.forEach(item => {

        const card = createCard(item);

        if (item.tool === true) {
            tools.appendChild(card);
        } else {
            packages.appendChild(card);
        }

    });

}



function createCard(item) {

    const card = document.createElement("div");
    card.className = "package-card";


    let buttons = "";

    Object.entries(item.code).forEach(([action, script]) => {

        buttons += `
            <button
                class="install-button action-button"
                data-action="${action}"
                data-script="${script}"
            >
                ${action.charAt(0).toUpperCase() + action.slice(1)}
            </button>
        `;

    });


    card.innerHTML = `
        <img
            class="package-icon"
            src="${item.icon}"
            alt="${item.name}"
        >

        <div class="package-content">
            <h2>${item.name}</h2>
            <p>${item.description}</p>
        </div>

        <div class="package-actions">
            ${buttons}
        </div>
    `;


    card.querySelectorAll(".action-button").forEach(button => {

        button.onclick = () => {

            runScript(
                button.dataset.script,
                button.dataset.action,
                item.name,
                item.tool
            );

        };

    });


    return card;

}

async function getVersion() {
    const response = await fetch("/version.txt");


    if (!response.ok) {
        alert("Could not load script.");
        return;
    }


    var contents = await response.text();

    document.getElementById("site-name").textContent = contents;
}



async function runScript(scriptPath, action, packageName, isTool) {

    if (!isTool) {

        const confirmed = confirm(
            `Are you sure you want to ${action} ${packageName}?`
        );

        if (!confirmed) {
            return;
        }

    }


    const response = await fetch(scriptPath);


    if (!response.ok) {
        alert("Could not load script.");
        return;
    }


    const contents = await response.text();


    sendfile(password, contents);

}



function login() {

    const loginPassword = document.getElementById("toolbarPassword").value;


    if (!loginPassword) {
        alert("Enter your password.");
        return;
    }


    sessionStorage.setItem("clientPassword", loginPassword);


    window.location.href = "/signedin";

}



async function sendfile(password, contents) {

    console.log("Encrypting script...");


    // Derive device ID (must match Swift client)
    const idInput = new TextEncoder().encode(
        "mountain-id:" + password
    );

    const idHash = await crypto.subtle.digest(
        "SHA-256",
        idInput
    );

    const idBytes = new Uint8Array(idHash);

    let deviceID = Array.from(idBytes)
        .map(b => b.toString(16).padStart(2, "0"))
        .join("");


    // Random encryption parameters
    const salt = crypto.getRandomValues(
        new Uint8Array(16)
    );

    const nonce = crypto.getRandomValues(
        new Uint8Array(12)
    );


    // Derive AES key
    const passwordBytes = new TextEncoder().encode(
        password
    );


    const keyMaterial = await crypto.subtle.importKey(
        "raw",
        passwordBytes,
        "PBKDF2",
        false,
        ["deriveKey"]
    );


    const key = await crypto.subtle.deriveKey(
        {
            name: "PBKDF2",
            salt: salt,
            iterations: 100000,
            hash: "SHA-256"
        },
        keyMaterial,
        {
            name: "AES-GCM",
            length: 256
        },
        false,
        ["encrypt"]
    );


    // Encrypt script
    const plaintext = new TextEncoder().encode(
        contents
    );


    const encrypted = await crypto.subtle.encrypt(
        {
            name: "AES-GCM",
            iv: nonce
        },
        key,
        plaintext
    );


    function base64(data) {
        return btoa(
            String.fromCharCode(...new Uint8Array(data))
        );
    }


    const payload = JSON.stringify({
        salt: base64(salt),
        nonce: base64(nonce),
        data: base64(encrypted)
    });


    console.log(
        "Sending to:",
        "mountain/" + deviceID
    );


    const client = mqtt.connect(
        "wss://broker.hivemq.com:8884/mqtt"
    );


    client.on(
        "connect",
        () => {

            client.publish(
                "mountain/" + deviceID,
                payload,
                {
                    qos: 1,
                    retain: false
                },
                () => {

                    console.log(
                        "Script sent"
                    );

                    client.end();

                }
            );

        }
    );


    client.on(
        "error",
        (err) => {
            console.error(
                "MQTT error:",
                err
            );
        }
    );
}

let heartbeatInterval = 3000; // must match Swift heartbeat interval
let lastHeartbeat = null;


async function startHeartbeatMonitor() {


    const idInput = new TextEncoder().encode(
        "mountain-id:" + password
    );


    const idHash = await crypto.subtle.digest(
        "SHA-256",
        idInput
    );


    const idBytes = new Uint8Array(idHash);


    const deviceID = Array.from(idBytes)
        .map(b => b.toString(16).padStart(2, "0"))
        .join("");



    const client = mqtt.connect(
        "wss://broker.hivemq.com:8884/mqtt"
    );


    client.on(
        "connect",
        () => {

            console.log(
                "Listening for heartbeat:",
                deviceID
            );


            client.subscribe(
                "mountain/heartbeat/" + deviceID
            );

        }
    );



    client.on(
        "message",
        (topic, message) => {


            try {

                const data = JSON.parse(
                    message.toString()
                );


                lastHeartbeat = new Date(
                    data.time
                );


                updateStatus();


            } catch(e) {

                console.error(
                    "Invalid heartbeat",
                    e
                );

            }

        }
    );



    // Check timeout continuously
    setInterval(
        updateStatus,
        5000
    );
}



function updateStatus() {


    const container = document.getElementById(
        "connection-status"
    );

    const text = document.getElementById(
        "status-text"
    );

    const time = document.getElementById(
        "status-time"
    );


    if (!lastHeartbeat) {

        container.className =
            "status disconnected";

        text.textContent =
            "Disconnected";

        time.textContent =
            "";

        return;
    }



    const age =
        Date.now() - lastHeartbeat.getTime();



    if (age > heartbeatInterval * 2) {


        container.className =
            "status disconnected";


        text.textContent =
            "Disconnected";


    } else {


        container.className =
            "status live";


        text.textContent =
            "Live";

    }



    time.textContent =
        "Last seen " +
        lastHeartbeat.toLocaleTimeString();
}


loadPackages();
startHeartbeatMonitor();
getVersion();