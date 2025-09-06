// ===========================================
// datatable-style.js
// ===========================================

window.customDataTableInitComplete = function(settings, json) {
  this.api().page.len(this.api().rows().count()).draw();

  $('.dataTables_scrollBody').on('scroll', function () {
    $('.dataTables_scrollHead').scrollLeft($(this).scrollLeft());
  });

  $(this.api().table().header()).css({
    'background-color': '#007bfa',
    'color': '#ffffff',
    'font-size': '14px'
  });

  $('.dt-buttons').css('margin-bottom', '10px');
  $('.dataTables_filter').css('margin-bottom', '10px');
  $('.dataTables_info').css({'margin-top': '-10px', 'margin-bottom': '50px'});

  $('.dt-button').addClass('action-button-primary');

  $('<style>')
  .prop('type', 'text/css')
  .html(`
    .dt-button.action-button-primary {
      margin-top: 0px;
      margin-right: 10px !important;
      color: white !important;
      background-color: #007bfa !important;
      border: none !important;
      border-radius: 2px !important;
      padding: 8px 16px !important;
      font-size: 14px !important;
      font-weight: bold !important;
    }
    .dt-button.action-button-primary:last-child {
      margin-right: 0px !important;
    }
    .dt-button.action-button-primary:hover {
      background-color: #007bfa !important;
      color: white !important;
    }

    .dataTables_filter {
      margin-right: 0px;
    }
    .dataTables_filter label {
      font-size: 14px;
      font-weight: bold;
      display: flex;
      align-items: center;
    }
    .dataTables_filter input {
      border: none;
      outline: none;
      border-bottom: 1px solid #ccc;
      padding: 5px;
      font-size: 14px;
      font-weight: normal;
    }
  `)
  .appendTo('head');
};

window.customCsvExport = function(csv) {
  var header = 'person_id;evaluation_date;sex;weight;height;bmi;bmi_zone\n';
  var rows = csv.split('\n');
  var processedRows = rows.slice(1).filter(row => row.trim() !== '').map(function(row) {
    row = row.replace(/\",\"/g, ';');
    var columns = row.split(';').map(function(val) {
      return val.replace(/\"/g, '');
    });
    
    var timestamp = parseInt(columns[1]);
    if (!isNaN(timestamp)) {
      var date = new Date(timestamp);
      var year = date.getFullYear();
      var month = ('0' + (date.getMonth() + 1)).slice(-2);
      var day = ('0' + date.getDate()).slice(-2);
      var hours = ('0' + date.getHours()).slice(-2);
      var minutes = ('0' + date.getMinutes()).slice(-2);
      var seconds = ('0' + date.getSeconds()).slice(-2);
      columns[1] = year + '-' + month + '-' + day + ' ' + hours + ':' + minutes + ':' + seconds;
    }

    [3, 4, 5].forEach(function(index) {
      if (columns[index] && columns[index].includes('.')) {
        columns[index] = columns[index].replace('.', ',');
      }
    });
    return columns.join(';');
  });
  return '\ufeff' + header + processedRows.join('\n');
};

window.customExcelExport = function(xlsx) {
  var sheet = xlsx.xl.worksheets['sheet1.xml'];
  var headers = ['person_id', 'evaluation_date', 'sex', 'weight', 'height', 'bmi', 'bmi_zone'];
  
  $('row:first c', sheet).each(function(i) {
    $(this).find('t').text(headers[i]);
  });
  
  $('row:gt(0)', sheet).each(function() {
    var $row = $(this);
    
    var $dateCell = $('c[r^="B"]', $row);
    var timestamp = parseInt($dateCell.find('v').text());

    if (!isNaN(timestamp)) {
      var date = new Date(timestamp);
      var year = date.getFullYear();
      var month = ('0' + (date.getMonth() + 1)).slice(-2);
      var day = ('0' + date.getDate()).slice(-2);
      var hours = ('0' + date.getHours()).slice(-2);
      var minutes = ('0' + date.getMinutes()).slice(-2);
      var seconds = ('0' + date.getSeconds()).slice(-2);
      
      $dateCell.attr('t', 's');
      $dateCell.html('<is><t>' + year + '-' + month + '-' + day + ' ' + hours + ':' + minutes + ':' + seconds + '</t></is>');
    }
    
    ['D', 'E', 'F'].forEach(function(colLetter) {
      var $cell = $('c[r^="' + colLetter + '"]', $row);
      var text = $cell.find('t').text();
      if (text) {
        $cell.find('t').text(text.replace('.', ','));
      }
    });
  });
};

window.customPdfExport = function(doc) {
  doc.defaultStyle.fontSize = 10;
  doc.styles.tableHeader.fontSize = 10;
  doc.pageMargins = [40, 20, 40, 20];
  doc.content[0].table.widths = Array(doc.content[0].table.body[0].length).fill('*');
  doc.content[0].table.body.forEach(function(row, index) {
    row.forEach(function(cell) {
      if (cell) cell.alignment = 'center';
    });
    if(index === 0) {
      row.forEach(function(cell) {
        cell.fillColor = '#007bfa';
        cell.color = '#ffffff';
        cell.bold = true;
      });
    }
  });
};
