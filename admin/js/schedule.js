// ======================================
// Kalinga Clinic Portal
// Medication Schedule
// ======================================

// ---------- Logout ----------

function logout() {

    if (confirm("Are you sure you want to logout?")) {

        window.location.href = "login.html";

    }

}

// ======================================
// Elements
// ======================================

const tbody = document.querySelector("tbody");
const searchInput = document.querySelector(".search-box input");

const addModal = document.getElementById("addModal");
const editModal = document.getElementById("editModal");
const deleteModal = document.getElementById("deleteModal");

const addForm = document.getElementById("addScheduleForm");
const editForm = document.getElementById("editScheduleForm");

const confirmDelete = document.getElementById("confirmDelete");

let selectedRow = null;

// ======================================
// Search
// ======================================

searchInput.addEventListener("keyup", function () {

    const value = this.value.toLowerCase();

    document.querySelectorAll("tbody tr").forEach(row => {

        row.style.display =
            row.innerText.toLowerCase().includes(value)
                ? ""
                : "none";

    });

});

// ======================================
// Open Add Modal
// ======================================

document.querySelector(".add-btn").onclick = function () {

    addForm.reset();

    addModal.style.display = "flex";

};

// ======================================
// Close Modals
// ======================================

function closeModal(modal){

    modal.style.display = "none";

}

document.querySelectorAll(".close").forEach(btn=>{

    btn.onclick=function(){

        closeModal(addModal);
        closeModal(editModal);
        closeModal(deleteModal);

    }

});

document.querySelector(".cancel-btn").onclick=function(){

    closeModal(deleteModal);

}

window.onclick=function(e){

    if(e.target==addModal) closeModal(addModal);

    if(e.target==editModal) closeModal(editModal);

    if(e.target==deleteModal) closeModal(deleteModal);

}

// ======================================
// Add Schedule
// ======================================

addForm.addEventListener("submit",function(e){

    e.preventDefault();

    const patient = addForm.elements[0].value;
    const medicine = addForm.elements[1].value;
    const time = addForm.elements[2].value;
    const frequency = addForm.elements[3].value;

    const id = String(tbody.rows.length+1).padStart(3,"0");

    const row = tbody.insertRow();

    row.innerHTML = `

        <td>${id}</td>

        <td>${patient}</td>

        <td>${medicine}</td>

        <td>${time}</td>

        <td>${frequency}</td>

        <td>

            <span class="active-status">

                Active

            </span>

        </td>

        <td>

            <button class="edit">

                <i class="fa-solid fa-pen"></i>

            </button>

            <button class="delete">

                <i class="fa-solid fa-trash"></i>

            </button>

        </td>

    `;

    bindButtons(row);

    closeModal(addModal);

});

// ======================================
// Edit
// ======================================

function openEdit(row){

    selectedRow = row;

    document.getElementById("editPatient").value =
        row.cells[1].innerText;

    document.getElementById("editMedicine").value =
        row.cells[2].innerText;

    document.getElementById("editTime").value =
        convertTime(row.cells[3].innerText);

    document.getElementById("editFrequency").value =
        row.cells[4].innerText;

    editModal.style.display="flex";

}

editForm.addEventListener("submit",function(e){

    e.preventDefault();

    selectedRow.cells[1].innerText =
        document.getElementById("editPatient").value;

    selectedRow.cells[2].innerText =
        document.getElementById("editMedicine").value;

    selectedRow.cells[3].innerText =
        document.getElementById("editTime").value;

    selectedRow.cells[4].innerText =
        document.getElementById("editFrequency").value;

    closeModal(editModal);

});

// ======================================
// Delete
// ======================================

function openDelete(row){

    selectedRow = row;

    deleteModal.style.display="flex";

}

confirmDelete.onclick=function(){

    if(selectedRow){

        selectedRow.remove();

    }

    closeModal(deleteModal);

}

// ======================================
// Bind Buttons
// ======================================

function bindButtons(row){

    row.querySelector(".edit").onclick=function(){

        openEdit(row);

    }

    row.querySelector(".delete").onclick=function(){

        openDelete(row);

    }

}

// ======================================
// Convert Time
// ======================================

function convertTime(time){

    if(time.includes("AM") || time.includes("PM")){

        const d = new Date("1970-01-01 "+time);

        let h = d.getHours().toString().padStart(2,"0");
        let m = d.getMinutes().toString().padStart(2,"0");

        return `${h}:${m}`;

    }

    return time;

}

// ======================================
// Initialize Existing Rows
// ======================================

document.querySelectorAll("tbody tr").forEach(row=>{

    bindButtons(row);

});

console.log("Medication Schedule Loaded");