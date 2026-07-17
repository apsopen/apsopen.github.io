let password = sessionStorage.getItem("clientPassword");

if (!password) {
    window.location.href = "/";
}

let packageStates = JSON.parse(
    localStorage.getItem("packageStates") || "{}"
);


function savePackageStates() {

    localStorage.setItem(
        "packageStates",
        JSON.stringify(packageStates)
    );

}


function getPackageState(item) {

    return packageStates[item.id]
        || Object.entries(item.states)
            .find(([_, state]) => state.default)[0];

}


function setPackageState(item, state) {

    packageStates[item.id] = state;

    savePackageStates();

}

let pendingActions = {};

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

    card.dataset.package = item.id;


    card.dataset.state =
        getPackageState(item);


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

        <div class="package-actions"></div>
    `;


    renderActions(
        card,
        item
    );


    return card;
}

function renderActions(card, item) {

    const actions =
        item.states[card.dataset.state].actions;


    const container =
        card.querySelector(".package-actions");


    container.innerHTML = "";


    actions.forEach(action => {


        const button =
            document.createElement("button");


        button.className =
            "install-button action-button";


        button.textContent =
            action.text;


        button.onclick = () => {

            runStateAction(
                card,
                item,
                action
            );

        };


        container.appendChild(button);

    });

}

async function runStateAction(card, item, action) {


    if (!item.tool) {

        const confirmed = confirm(
            `Are you sure you want to ${action.id} ${item.name}?`
        );


        if (!confirmed) {
            return;
        }
    }



    const button =
        event?.target;



    if (button) {

        button.disabled = true;

        button.classList.add(
            "running"
        );

        button.textContent =
            action.running;
    }



    const response =
        await fetch(action.script);



    if (!response.ok) {

        alert(
            "Could not load script."
        );

        return;
    }



    const contents =
        await response.text();



    await sendfile(
        password,
        contents,
        {
            package: item.id,
            action: action.id
        }
    );


    pendingActions[item.id] = {
        card,
        item,
        action
    };
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

async function startStatusMonitor() {


    const idInput = new TextEncoder().encode(
        "mountain-id:" + password
    );


    const idHash =
        await crypto.subtle.digest(
            "SHA-256",
            idInput
        );


    const deviceID =
        Array.from(
            new Uint8Array(idHash)
        )
        .map(
            b => b.toString(16).padStart(2,"0")
        )
        .join("");



    const client = mqtt.connect(
        "wss://broker.hivemq.com:8884/mqtt"
    );



    client.on(
        "connect",
        () => {

            client.subscribe(
                "mountain/status/" + deviceID
            );

        }
    );



    client.on(
        "message",
        (_, message) => {


            const data =
                JSON.parse(
                    message.toString()
                );


            if (data.status !== "finished") {
                return;
            }


            const pending = pendingActions[data.package];


            if (!pending) {
                return;
            }


            if (!data.success) {

                alert(
                    `${pending.item.name} ${pending.action.text} failed`
                );


                renderActions(
                    pending.card,
                    pending.item
                );


                delete pendingActions[data.package];

                return;
            }



            const nextState =
                pending.action.on_finish;



            pending.card.dataset.state =
                nextState;


            setPackageState(
                pending.item,
                nextState
            );



            renderActions(
                pending.card,
                pending.item
            );



            delete pendingActions[data.package];

        }
    );
}

async function sendfile(password, contents, metadata) {

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

        data: base64(encrypted),

        package: metadata.package,

        action: metadata.action
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
startStatusMonitor();
getVersion();