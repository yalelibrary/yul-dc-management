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

import "@fortawesome/fontawesome-free/css/all.css";
import "@fortawesome/fontawesome-free/js/all.js";

//= require jquery3
//= require popper
//= require bootstrap-sprockets

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)
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



    dataTable = $('.is-datatable').dataTable({
      "deferLoading":true,
      "processing": true,
      "serverSide": true,        
      "stateSave": true,
      "ajax": {
        "url": $('.is-datatable').data('source')
      },
      "pagingType": "full_numbers",
      "bAutoWidth": false, // AutoWidth has issues with hiding and showing columns as startup
      "columns": columns,
      "order": columnOrder(columns),
      "lengthMenu": [[50, 100, 500, -1], [50, 100, 500, "All"]],
      "sDom":hasSearch?'Blrtip':'<"row"<"col-sm-12 col-md-6"l><"col-sm-12 col-md-6"f>>rtip',
      buttons: [
        {
          text: "Clear Filters",
          className: "clear-filters-button",
          action: () => {
            dataTable.api().columns().search('').visible( true, true ).order('asc' ).state.clear().draw() ;
            $(".datatable-search-row input").val("");
          }
        },
        {
          extend: 'colvis',
          text: "\u25EB"
        }
      ],
      // pagingType is optional, if you want full pagination controls.
      // Check dataTables documentation to learn more about
      // available options.
      initComplete: function () {
        if (hasSearch) onColumnsUpdate(this);
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
    })
  }

  // Allows all datatables, no matter the amount of columns, to have 100% width
  const tableWidth = document.getElementsByClassName('is-datatable')[0].clientWidth;
  const tableHeadWidth = document.getElementsByClassName('table-head')[0].clientWidth;
  if (tableHeadWidth <= tableWidth) {
    $('.is-datatable').addClass('expanded')
  }
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

