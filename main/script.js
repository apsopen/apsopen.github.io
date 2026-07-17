async function getVersion() {

    const response = await fetch("/version.txt");


    if (!response.ok) {

        alert("Could not load version.");
        return;

    }


    const contents = await response.text();


    document.getElementById("site-name").textContent =
        contents;

}


getVersion();