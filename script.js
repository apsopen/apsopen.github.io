const loginForm = document.getElementById("loginForm");

loginForm.addEventListener("submit", function (event) {
    event.preventDefault();

    const password = document.getElementById("password").value.trim();

    if (password.length === 0) {
        alert("Please enter your password.");
        return;
    }

    // Replace with real authentication later.
    window.location.href = "/signedin";
});