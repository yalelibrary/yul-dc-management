// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")
require('datatables.net-bs4')(window, $)
require('datatables.net-buttons-bs4')(window, $)
require('datatables.net-buttons/js/buttons.colVis.js')(window, $)
require('datatables.net-buttons/js/buttons.html5.js')(window, $)
require('datatables.net-buttons/js/buttons.print.js')(window, $)
require('datatables.net-responsive-bs4')(window, $)
require('datatables.net-select')(window, $)
import 'bootstrap';
require("datatables.net-bs4/css/dataTables.bootstrap4.min.css")
require("datatables.net-buttons-bs4/css/buttons.bootstrap4.min.css")
require("datatables.net-select-bs4/css/select.bootstrap4.min.css")
require("datatables.net-responsive-bs4/css/responsive.bootstrap4.min.css")

//= require jquery3
//= require popper
//= require bootstrap-sprockets

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)
$( document ).on('turbolinks:load', function() {
  if($('.is-datatable').length > 0 && !$('.is-datatable').hasClass('dataTable')){
    $('.is-datatable').dataTable({
      "processing": true,
      "serverSide": true,
      "ajax": {
        "url": $('.is-datatable').data('source')
      },
      "pagingType": "full_numbers",
      "columns": JSON.parse($(".datatable-data").text()),
      // This will order all datatables by the first column descending
      "order": [[0, "desc"]],
      "lengthMenu": [[50, 100, 500, -1], [50, 100, 500, "All"]]
      // pagingType is optional, if you want full pagination controls.
      // Check dataTables documentation to learn more about
      // available options.
    })
  }
});
