// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")
import * as bootstrap from 'bootstrap';
import jszip from 'jszip';
import pdfmake from 'pdfmake';
import DataTable from 'datatables.net-bs5';
import "datatables.net-buttons-bs5"
import "datatables.net-buttons/js/buttons.colVis.js"
import "datatables.net-buttons/js/buttons.html5.js"
import "datatables.net-buttons/js/buttons.print.js"
import "datatables.net-select-bs5"

import "@fortawesome/fontawesome-free/js/all.js";

window.DataTable = DataTable
DataTable.use(bootstrap);
DataTable.Buttons.jszip(jszip);
DataTable.Buttons.pdfMake(pdfmake);

//= require jquery3
//= require popper
//= require bootstrap-sprockets

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)
global.$ = jQuery;

let dataTable;
$( document ).on('turbolinks:load', function() {
  let initialColumnSearchValues = [];
  if($('.is-datatable').length > 0 && !$('.is-datatable').hasClass('dataTable')){
    let columns = JSON.parse($(".datatable-data").text());
    // load the information about which columns are visible for this page
    let dataTableStorageKey = "DT-columns-" + btoa(document.location.href);
    let columnInfo = localStorage.getItem(dataTableStorageKey);
    try { columnInfo = columnInfo && JSON.parse(columnInfo); } catch (e) { columnInfo = null; }
    columns = columns.map(function (col) {if (columnInfo && columnInfo[col.data] && columnInfo[col.data].hidden) col.visible = false; return col } )
    let hasSearch = columns.some(function(col){return col.searchable;});
    const onColumnsUpdate = function(dataTable) {
      let colVisibilityMap = createSearchRow(dataTable);
      localStorage.setItem(dataTableStorageKey, JSON.stringify(colVisibilityMap));
    }
    const createSearchRow = function(dataTable) {
      $('#search-row').remove();
      let searchRow = $("<tr role='row' id='search-row'></tr>");
      let index = 0;
      let colVisibilityMap = {}
      dataTable.api().columns().every(function () {
        let column = this;
        let searchInit = initialColumnSearchValues[index];
        let colDef = columns[index++];
        colVisibilityMap[colDef.data] = {hidden:!column.visible()};
        if (!column.visible()) return;
        if (colDef.searchable) {
          let th = $("<th class='datatable-search-row'/>");
          let input = null;
          if (colDef.options) {
            input = $("<select><option>All</option>" + colDef.options.map(function (option) {
              if (typeof option==="string"){
                option={value:option, label:option}
              }
              if (option.selected) {
                column.search(option.value)
              }
              return "<option value='"+ option.value +"' "+ (option.selected ? "selected": '') + ">" + option.label + "</option>"
            }) + "</select>");
          } else {
            input = $("<input type='text' size='12' placeholder='" + $(column.header()).text() + "' />");
          }
          (input).on('keyup change clear', function () {
            let v = this.value;
            if (v === "All" && colDef.options) v = "";
            if (column.search() !== v) {
              column.search(v);
              scheduleDraw();
            }
          });
          searchRow.append(th.append(input));
          input.val(searchInit);
        } else {
          searchRow.append("<th />");
        }
      });
      $(dataTable.api().table().header()).append(searchRow);
      // store the information about which columns are visible for this page
      return colVisibilityMap;
    }

    var oldExportAction = function (self, e, dt, button, config) {
      if (button[0].className.indexOf('buttons-csv') >= 0) {
        if ($.fn.dataTable.ext.buttons.csvHtml5.available(dt, config)) {
          $.fn.dataTable.ext.buttons.csvHtml5.action.call(self, e, dt, button, config);
        }
        else {
          $.fn.dataTable.ext.buttons.csvFlash.action.call(self, e, dt, button, config);
        }
      } else if (button[0].className.indexOf('buttons-print') >= 0) {
        $.fn.dataTable.ext.buttons.print.action(e, dt, button, config);
      }
    };

    var newExportAction = function (e, dt, button, config) {
      var self = this;
      var oldStart = dt.settings()[0]._iDisplayStart;

      dt.one('preXhr', function (e, s, data) {
        // Just this once, load all data from the server...
        data.start = 0;
        data.length = 150000;

        dt.one('preDraw', function (e, settings) {
          // Call the original action function
          oldExportAction(self, e, dt, button, config);

          dt.one('preXhr', function (e, s, data) {
            // DataTables thinks the first item displayed is index 0, but we're not drawing that.
            // Set the property to what it was before exporting.
            settings._iDisplayStart = oldStart;
            data.start = oldStart;
          });

          // Reload the grid with the original page. Otherwise, API functions like table.cell(this) don't work properly.
          setTimeout(dt.ajax.reload, 0);

          // Prevent rendering of the full data to the DOM
          return false;
        });
      });

      // Requery the server with the new one-time export settings
      dt.ajax.reload();
    };

    dataTable = $('.is-datatable').dataTable({
      "deferLoading":true,
      "ordering": true,
      "processing": true,
      "serverSide": true,
      "stateSave": true,
      "ajax": {
        "url": $('.is-datatable').data('source')
      },
      "pagingType": "full_numbers",
      "bAutoWidth": false, // AutoWidth has issues with hiding and showing columns as startup
      columnDefs: [
        { "width": "250px", "targets": [0] },
        { "width": "200px", "targets": columns.slice(1).map((x, index) => index + 1) } // every column except the first one
      ],
      "columns": columns,
      "order": columnOrder(columns),
      "lengthMenu": [[50, 100, 500], [50, 100, 500]],
      // This will disable the export all button when there are more than 12K records
      "fnDrawCallback": function( oSettings ) {
        $('.export-all').attr('disabled', oSettings.fnRecordsDisplay() > 12000)
      },
      "sDom":hasSearch?'Blrtip':'<"row"<"col-sm-12 col-md-6"l><"col-sm-12 col-md-6"f>>rtip',
      buttons: [
        {
          text: "Clear Filters",
          className: "clear-filters-button",
          action: () => {
            dataTable.api().state.clear();
            location.reload();
          }
        },
        {
          extend: 'colvis',
          text: "\u25EB",
          className: 'buttons-colvis'
        },
        {
          extend: 'csvHtml5',
          text: "CSV",
          exportOptions: {
            columns: ':visible',
          },
          customize: function (csv) {
            return format_csv(csv)
          }
        },
        {
          extend: 'excelHtml5',
          title: null
        },
        {
          extend: 'csvHtml5',
          action: newExportAction,
          text: "All Matching Entries",
          className: "export-all",
          customize: function (csv) {
            return format_csv(csv)
          }
        }, 
      ],
      // pagingType is optional, if you want full pagination controls.
      // Check dataTables documentation to learn more about
      // available options.
      initComplete: function () {
        $('.dt-info').appendTo('.main-content');
        $('.dt-paging').appendTo('.main-content');
        if (hasSearch) onColumnsUpdate(this);
        
        // Add handler for column visibility changes
        $(document).on('click', '.dt-button-collection .dropdown-item', function() {
          $(this).toggleClass('active');
        });
      },
      stateLoaded: function (e, setting, data) {
        // load the search settings when state is loaded by the datatable to fill in the inputs.
        setting.columns.forEach((c) => initialColumnSearchValues.push(c.search.search));
      }

    })
    dataTable.api().draw();

    $('.is-datatable').on( 'column-visibility.dt', function ( e, settings, column, state ) {
      // Check for data-destroying because this gets called after turbo links updates document.location and the
      // datatable is destroyed in turbolinks:before-cache. In that case, don't create the search row or
      // write the column information to localStorage using the wrong document.location.href
      if (hasSearch && "true" !== $( '.is-datatable' ).data("destroying")) onColumnsUpdate($( '.is-datatable' ).dataTable());
    } );


    $(document).on('turbolinks:before-cache', function(){
      $( '.is-datatable' ).data("destroying", "true");
      dataTable.api().destroy();
      $('#search-row').remove();
      $('.dt-info, .dt-paging').remove(); // Remove pagination elements
    })
  }

  $('.export-all span').hover(
      function() {
        if ($(this).parent("button").attr('disabled')) {
          $(this).html("Please use all parents batch job");
        }
      }, function() {
        if ($(this).parent("button").attr('disabled')) {
          $( this ).html("All Matching Entries");
        }
      }
  )
});

//  Delay the redraw so that if more changes trigger a redraw
//  it will wait and make one request to the server.
let drawTimer = 0;
let scheduleDraw = function() {
  if (drawTimer) clearInterval(drawTimer);
  drawTimer = setInterval(triggerDraw, 500);
}
let triggerDraw = function() {
  clearInterval(drawTimer);
  drawTimer = 0;
  dataTable.api().draw();
}

// This will order all datatables by the first column descending
// unless some columns have sort_order set in the column def
// sort_order needs to be in the column in the datatable @view_columns, and the view page needs to pass those values
// to the page.  See user_datatable.rb and views/users/index.html.erb for example.
const columnOrder = (columns) => {
  if ( columns.filter((c)=>c.sort_order).length === 0 ) return [[0, 'desc']]
  let columnOrder = []
  columns.forEach((c,ix)=>{
    if ( c.sort_order ) {
      columnOrder.push([ix, c.sort_order])
    }
  })
  return columnOrder;
}

// used to change the styling of the csv
const format_csv = (csv) => {
  var lines = csv.split("\n").length;
  var csvRows = csv.split('\n');
  var formatted_header = snake_case(csvRows[0])
  var csv_content = []
  for (let i = 1; i < lines; i++) {
    csv_content += csvRows[i]
    csv_content += '\n'
  }
  return (formatted_header + '\n' + csv_content);
}

// used to convert csv headers to snake case
function snake_case(string) {
  return string.toLowerCase().replace(/ /g, '_')
}

$( document ).on('turbolinks:load', function() {
  let show_hide_template_link = function(){
    let batch_action = $('#batch_process_batch_action').val();
    $(".download_batch_process_template").attr("href", "batch_processes/download_template?batch_action=" + $('#batch_process_batch_action').val());
    if (batch_action) {
      $(".download_batch_process_template").fadeIn();
    } else {
      $(".download_batch_process_template").fadeOut();
    }
  }
  $('#batch_process_batch_action').on('change', show_hide_template_link)
  show_hide_template_link();
})


$( document ).on('turbolinks:load', function() {
  $('.select-all-btn').click( function(e) {
    select_all($(this).data('target-select'));
    e.preventDefault();
    return false;
  })
})

function select_all( select ) {
  $(select + ' option').prop('selected', true);
}

// This will refresh batch process datatable every 30 seconds
$( document ).on('turbolinks:load', function() {
  if ( dataTable && $(".is-datatable").data("refresh")) {
    setTimeout( function() {
      dataTable.api().ajax.reload(null, false);
      let interval = setInterval(function () {
        dataTable.api().ajax.reload(null, false);
      }, 30000);
      $(document).on('turbolinks:before-cache turbolinks:before-render', function () {
        clearTimeout(interval);
      });
    }, 5000);
  }
})

// This will trigger a modal when adding redirect
$( document ).on('turbolinks:load', function() {
  $('.parent-edit').on('submit', function() {
    if ( $("#parent_object_redirect_to").val() !== '' && $("#parent_object_redirect_to").length ) {
      return confirm('Adding Redirect To information will remove that object from public view.  Do you wish to continue?');
    }
  })
})

// This will filter the version table
$( document ).on('turbolinks:load', function() {
  var url = window.location.href;
  var checkbox = $('#user');
  checkbox.on('change', function() {
    if ( checkbox.is(":checked") ) {
      if ( url.indexOf('false') !== -1 ) {
        var some_url = url.replace('checked=false', 'checked=true');
        window.location.href = some_url;
      }
    } else {
      var all_url = url.replace('checked=true', 'checked=false');
      window.location.href = all_url
    }
  })
})

// This will change the filter icon on the parent object show page
$( document ).on('turbolinks:load', function() {
  var values = $('.table-row').find('td:eq(1)');
  values.each(function() {
    var value = $(this).text()
    if (value == '') {
      $(this).closest('tr').toggleClass('hidden');
    }
    $('tr:not(.hidden):odd').css('background-color', '#F2F2F2');
    $('tr:not(.hidden):even').css('background-color', '#FFFFFF');
  })
  $('#filter-icon').click(function() {
    $(this).find('svg').toggleClass('fa-filter-circle-xmark fa-filter ');
    var values = $('.table-row').find('td:eq(1)');
    values.each(function() {
      var value = $(this).text()
      if (value == '') {
        $(this).closest('tr').toggleClass('hidden');
      }
      $('tr:not(.hidden):odd').css('background-color', '#F2F2F2');
      $('tr:not(.hidden):even').css('background-color', '#FFFFFF');
    })
  })
})

// Enables/Disabled permission set dropdown based on visibility
$( document ).on('turbolinks:load', function() {
  if($('#parent_object_visibility').val() != 'Open with Permission') {
    $('#parent_object_permission_set_id').prop('disabled', true);
  }
  $('#parent_object_visibility').on('input change', function() {
    if($(this).val() != 'Open with Permission') {
      $('#parent_object_permission_set_id').prop('disabled', true);
    } else {
      $('#parent_object_permission_set_id').prop('disabled', false);
    }
  });
});

// Enables/disabled permission request datepicker based on selected request_status
$( document ).on('turbolinks:load', function() {
  if($('#open_with_permission_permission_request_request_status_denied:checked').val() == 'Denied' || $('#open_with_permission_permission_request_request_status_approved:checked').val() == undefined) {
    $('#open_with_permission_permission_request_access_until').prop('disabled', true);
  }
  $('#open_with_permission_permission_request_request_status_approved').on('input change', function() {
    if($(this).val() == 'Approved') {
      $('#open_with_permission_permission_request_access_until').prop('disabled', false);
    }
  });
  $('#open_with_permission_permission_request_request_status_denied').on('input change', function() {
    if($(this).val() == 'Denied') {
      $('#open_with_permission_permission_request_access_until').prop('disabled', true);
    }
  });
});

