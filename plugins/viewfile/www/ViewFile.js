var viewFile = function viewFile(url) {
  cordova.exec( successFn
              , failureFn
              , "ViewFile"
              , "ViewFromUrl"
              , [{"url" : url}]
              );
};

window.viewFileFromUrl = viewFile;

if (module && module.exports) {
  module.exports = viewFile;
}

