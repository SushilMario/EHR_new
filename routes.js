const routes = require('next-routes')();

routes
    .add('/users/admin', '/users/admin/show')
    .add('/users/doctors/:doctorAddress', '/users/doctors/show')
    .add('/users/patients/:patientAddress', '/users/doctors/show');

module.exports = routes;