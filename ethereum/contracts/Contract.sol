// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.11;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles 
{
    struct Role 
    {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal 
    {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal 
    {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) 
    {
        return role.bearer[account];
    }
}

contract Contract
{
    using Roles for Roles.Role;

    Roles.Role private adminRole;
    Roles.Role private doctorRole;
    Roles.Role private patientRole;

    struct Doctor
    {
        string name;
        string phoneNumber;
        uint[] recordNumberList;
        uint recordCount;
    }

    struct Patient
    {
        string name;
        string phoneNumber;
        uint[] recordNumberList;
        uint recordCount;
    }

    struct Record
    {
        uint recordNumber;
        address doctorAddress;
        address patientAddress;
        string patientHistoryDescription;
        uint[] appointmentNumberList;
    }

    struct Appointment
    {
        uint number;
        address patientAddress;
        address doctorAddress;
        string diagnosis;
        string treatmentPrescribed;
    }

    mapping(address => Doctor) addressToDoctorMapping;
    mapping(address => Patient) addressToPatientMapping;
    mapping(address => address) patientToDoctorMapping;

    Appointment[] appointmentList;
    Record[] public recordList;

    address[] public doctorList;
    address[] public patientList;

    address public admin;

    constructor() 
    {
        admin = msg.sender;
        adminRole.add(admin);
    }
    
    //Add Doctor

    function addDoctor(address doctorAddress, string memory doctorName, string memory phoneNumber) public adminOnly
    {
        require(doctorAddress != msg.sender, "You are not eligible for this role");

        doctorRole.add(doctorAddress);

        Doctor memory doctor;
        
        doctor.name = doctorName;
        doctor.phoneNumber = phoneNumber;
        doctor.recordCount = 0;

        doctorList.push(doctorAddress);

        addressToDoctorMapping[doctorAddress] = doctor;
    }

    function getDoctorList() public view returns(address[] memory)
    {
        return doctorList;
    }

    function getDoctor(address doctorAddress) public view returns(string memory, string memory)
    {
        Doctor memory doctor = addressToDoctorMapping[doctorAddress];

        return (
            doctor.name,
            doctor.phoneNumber
        );
    }

    // Add Patient

    function addPatient(address patientAddress, string memory patientName, string memory phoneNumber) public adminOnly
    {
        require(patientAddress != msg.sender, "You are not eligible for this role");

        patientRole.add(patientAddress);

        Patient memory patient;
        
        patient.name = patientName;
        patient.phoneNumber = phoneNumber;
        patient.recordCount = 0;

        addressToPatientMapping[patientAddress] = patient;

        patientList.push(patientAddress);
    }

    // Assign doctor to patient and vice versa

    function assign(address patientAddress, address doctorAddress) public adminOnly
    {
        patientToDoctorMapping[patientAddress] = doctorAddress;
    }

   // check if is Doctor

    function isDoctor(address givenAddress) public view returns(bool)
    {
        return doctorRole.has(givenAddress);
    }

    // Check if is Patient

    function isPatient(address givenAddress) public view returns(bool)
    {
        return patientRole.has(givenAddress);
    }

    // Check if is assigned to Doctor

    function isAssignedToDoctor(address patientAddress) public view doctorOnly returns(bool)
    {
        return patientToDoctorMapping[patientAddress] == msg.sender;
    }

    // Create medical record

    function createRecord(address patientAddress, string memory patientHistoryDescription) public doctorOnly assignedDoctorOnly(patientAddress) notForAdmin
    {
        Record memory record;

        record.recordNumber = recordList.length;
        record.doctorAddress = msg.sender;
        record.patientAddress = patientAddress;
        record.patientHistoryDescription = patientHistoryDescription;

        Doctor storage doctor = addressToDoctorMapping[msg.sender];
        Patient storage patient = addressToPatientMapping[patientAddress];

        doctor.recordNumberList.push(record.recordNumber);
        doctor.recordCount = doctor.recordNumberList.length;
        patient.recordNumberList.push(record.recordNumber);
        patient.recordCount = patient.recordNumberList.length;

        recordList.push(record);
    }

    // Get record count

    function getRecordCount(address senderAddress) public view assignablesOnly(senderAddress) returns(uint)
    {
        if(doctorRole.has(msg.sender))
        {
            return addressToDoctorMapping[msg.sender].recordCount;
        }
        else
        {
            return addressToPatientMapping[msg.sender].recordCount;
        }
    }

    // Get record numbers

    function getRecordNumbers(address senderAddress) public view assignablesOnly(senderAddress) returns(uint[] memory)
    {
        if(doctorRole.has(msg.sender))
        {
            return addressToDoctorMapping[msg.sender].recordNumberList;
        }
        else
        {
            return addressToPatientMapping[msg.sender].recordNumberList;
        }
    }

    // Get a medical record
    
    function getMedicalRecord(uint recordNumber) public view returns(Record memory)
    {
        Record memory record = recordList[recordNumber];

        require((record.patientAddress == msg.sender || record.doctorAddress == msg.sender));

        return record;
    }

    // Create appointment

    function createAppointment
        (address patientAddress, string memory diagnosis, string memory treatmentPrescribed, uint recordNumber) 
        public doctorOnly assignedDoctorOnly(patientAddress) notForAdmin
    {
        Appointment memory appointment;

        appointment.number = appointmentList.length;
        appointment.patientAddress = patientAddress;
        appointment.doctorAddress = msg.sender;
        appointment.diagnosis = diagnosis;
        appointment.treatmentPrescribed = treatmentPrescribed;

        appointmentList.push(appointment);

        addAppointmentToRecord(recordNumber, appointment.number);
    }

    // Add appointment to medical record

    function addAppointmentToRecord(uint recordNumber, uint appointmentNumber) internal
    {
        Record storage record = recordList[recordNumber];

        record.appointmentNumberList.push(appointmentNumber);
    }

    /*
        Modifiers
    */


    modifier adminOnly()
    {
        require(adminRole.has(msg.sender) == true, 'Admin only');
        _;
    }

    modifier doctorOnly()
    {
        require(doctorRole.has(msg.sender) == true, 'Doctor only');
        _;
    }

    modifier patientOnly()
    {
        require(patientRole.has(msg.sender) == true, 'Patient only');
        _;
    }

    modifier assignedDoctorOnly(address patientAddress)
    {
        require(patientToDoctorMapping[patientAddress] == msg.sender, "You haven't been assigned this patient");
        _;
    }

    modifier assignablesOnly(address givenAddress)
    {
        require(doctorRole.has(givenAddress) || patientRole.has(givenAddress));
        _;
    }

    modifier notForAdmin()
    {
        require(!adminRole.has(msg.sender), 'Not for admin');
        _;
    }
}