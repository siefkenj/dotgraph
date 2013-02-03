/***************
 * Modifies the .parse method of DotParser
 * to first preprocess and remove any '\' followed
 * by newlines from the text before handing
 * it off to DotParser.parse
 **/

(function (DotParser) {
    originalParse = DotParser.parse;
    DotParser.parse = function (src) {
        src = src.replace("\\\n","","g");
        return originalParse.call(DotParser, src);
    }
})(DotParser);
