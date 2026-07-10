const loginForm = document.getElementById("loginForm");

loginForm.addEventListener("submit", function (e) {

    e.preventDefault();

    const email = document.getElementById("email").value.trim();
    const password = document.getElementById("password").value;

    // Temporary Admin Account
    const adminEmail = "admin@gmail.com";
    const adminPassword = "password";

    if (email === adminEmail && password === adminPassword) {

        alert("Welcome Admin!");

        window.location.href = "dashboard.html";

    } else {

        alert("Invalid Email or Password.");

    }

});