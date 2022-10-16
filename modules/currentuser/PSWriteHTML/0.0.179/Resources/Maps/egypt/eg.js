/*!
 *
 * Jquery Mapael - Dynamic maps jQuery plugin (based on raphael.js)
 * Requires jQuery and Mapael >=2.0.0
 *
 * Map of eg
 * 
 * @author ismael cadenas
 */
(function (factory) {
    if (typeof exports === 'object') {
        // CommonJS
        module.exports = factory(require('jquery'), require('jquery-mapael'));
    } else if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define(['jquery', 'mapael'], factory);
    } else {
        // Browser globals
        factory(jQuery, jQuery.mapael);
    }
}(function ($, Mapael) {

    "use strict";
    
    $.extend(true, Mapael,
        {
            maps :  {
                eg : {
                    width : 1000,
                    height : 889,
                    getCoords : function (lat, lon) {
                        // todo
                        return {"x" : lon, "y" : lat};
                    },
                    'elems': {
                        "EGY99" : "M979.6 864.4l-0.2 1.5-0.1-0.9-0.9 0.1-1.3 0.1 0.1-1.2 0.3-0.3 0.1-0.6 0.9-0.4 0.3 0.3-0.6 0.4 0.5 0.1 0.5 0.7 0.4 0.2z m-37.5-34.9l-0.2 0.4-0.6-0.9-0.4-0.5-0.2-0.5-0.6-0.3-0.7-0.7 2-0.1 0.8 1.4 0 0.4 0.2 0.5-0.3 0.3z m-11.3-7.7l-0.1 0.4 0.2 0.5 0.1 0.4-0.5-0.1-0.4-1.2-1.1 1 0.4 0.5-0.5 0.5-0.3-1.5 1.1-1.1 0.4-1 0.8-0.5-0.3 1 0.1 0.2 0.1 0.9z m12.7-4.8l0.1 0.4 0.5 0 1.1 0.2 0.4 0.3-1.8 0-1 0-0.4 0.2-0.8-0.6 0.6 0.1 0.5-0.2 0.6-0.1-0.1-1.2 0.6 0.4-0.3 0.5z m-42.9-38.8l0.3 0.4-0.1 0.8 1 1.2 0.7 0.7-0.3 0.1-0.9-0.2-0.4-0.1-0.4-0.6-0.5-0.1-0.7-1-0.4-0.4-0.9-0.1-0.2 0.4-0.3-0.2-1.7-0.4-0.9 0.2-1 0.7-0.5 0.7 0.8 0.3 0.2 0.4-0.4 0-0.7-0.4-1.3-0.4 0-0.4-0.2-0.4-0.4-0.6 0.3-0.1 0.5 0.2 1.2-0.3 0.8 0 1.1-0.3 0.8 0 0.7-0.4 0.8 0.4 1.1 0.2 0.6-0.1 1-0.6 0.4 0.1-0.1 0.3z m41.6-32.8l-1.1 0.8-0.4-0.8 0-0.8-0.1-1.2 1.1 0.3 0.7 0.6-0.2 1.1z",
                        "EGY1530" : "M537.2 53.4l-1-0.3-0.6 4.5-0.8 2.5-0.1 0.8 0.4 0.5 2 0.8 0.9-0.3 0.7-0.5 0.8-0.2 0.8-0.1 0.8-0.4 0.4 0.1 0.3 0.2-0.1 0.5 0.1 0.7-0.5 2.7-0.2 0.5-0.9 0.5-0.9 0.2-0.9 0.2-0.7 1-0.2 1.2 0.3 0.8 0.4 0.7 0.1 1.2-0.6 0.8-0.8 0.7-0.3 0.8 1.1 1-1 0.5-0.7 0.1 1.1 0.8 0.4 0.5 0.2 0.4 0 1-0.2 0.3-0.3 0-0.6 0.3-1.9 0.6-0.4 0.4 0.3 0.7 0.3 0.6 0.8 0.9 0.3 4 0.6 2.3 0.2 0.3 0.7 0.3 0.2 0.7 0.3 2.6 1 4.3-0.2 2.6-1.2 4.3-0.2 2.2-1.8-1.1-0.6-1.1-1.7-1.6-0.7-0.5-0.4-0.7-0.1-0.7-0.6-0.5-0.6-0.4-1.1-0.6-1-0.4-2.9-0.3-1.2 0.2-0.5 0-0.4-0.8-1.7-2.9-0.5-0.3-1.4 0.7-1 0.1-1.2-0.1-1.4 0.2-0.4-0.1-0.8-1-0.6-0.1-0.7-0.3-1.4-1.6-0.8-0.4-1-0.1-0.9 0.2-0.9 0.3-0.9 0.4-0.9 0.5-4.1 0.5-0.9 0.3-2.1 1.3-0.2-1.4-0.4-1-0.8-0.4-0.4-0.6 0.6-1.4 0.8-1.2 0.4-0.4-0.3-1.5-0.9-0.1-1.1 0.4-1.1-0.4-0.1-1.1 0.6-1.2 0.8-1.2 0.5-0.5 2.1-0.6 1-0.5 0.2-0.9-0.8-0.6-1.2 0.1-2.5 0.5 1.9-1.3 0.4-0.6 0.2-0.9 0.1-1.1-0.3-0.9-0.9-0.4-1.8-0.4 0.3-1 1-1.2 0.8-1.3-0.4-1.6-2-3-0.1-0.5 0.9-0.7 0.8-1.9 0.6-0.1 0.8 0.4 4.8 1.7 1-0.2 1.4-0.5 1.2-0.2 1.3 0.2 0.8-0.5-0.1-0.3 0.4-0.4 0.9-0.5 0.8-0.5 0.7-0.2 5.9-0.4 1.3-0.6 0.8-0.8 0.4-1.9 0.4-0.8 0.2-0.8 0.1-0.5-0.1-1.6 0-1 0.1-0.9 0.6-0.8 4.4 0.2 1.8 0.8 0.9 0 1.8-1.6 0.9-0.5 0.9-0.1 0.9 0.1 0.8 0.3 0.5 0.3 1.7 1.6z",
                        "EGY1531" : "M647.8 66.4l3.3 33 0.2 8.4 0.3 2 0.3 1.2 0.1 0.4 7.5 12.1 4.4 11.2-15.6-1.1-2.5 0.3-2.7 0.8-0.6 0.3-3.2 3.1-0.4 0.2-2.4 1.1-0.4 0.1-1 0-4.2-0.7-1.5-0.4-1.1-0.5-2.4-1.6-7.1-0.5-29.4 1-3.6-10.1-2.5-9.9-0.3-3.4-0.7-2.4-0.8-1.1-0.9-0.7-1-1.2-0.3-1 0-1 0.4-0.5 0.9 0.2 0.4 0 3.7 1.1 0.3 0.1 3.6 0 2.1-0.3 1.3-0.4 2.1-0.4 2.4 0 2.2-1.4 2.5-2.6 5.4-7.2 1.8-3.7 0.8-2.5-1-5 0-3.7 1.1-2.3 0.5-1.7 1.1-2 1.2-3.5 2.4-3.1 0.5-1.5 0.1-1.2 0-1.1-0.8-2.9-1.4-1.1-1.2-0.7-1.4-1.8-0.1-0.6 0.3 0-0.3-0.7 7.1-0.8 2.9-0.7 2.1-1 1.7-0.5 23.8 13.9z",
                        "EGY1532" : "M537.4 105.2l0.9 1.3-1.1 0.4-0.7-0.4-0.5-0.6-0.5-0.1-0.5 0.7-0.1 0.9 0.1 1 0.5 0.7 0 0.6-2.3 2-1.3 0.5-0.4 0.3 0.1 1.3-0.1 0.5-0.6 0.5-1.4 0.3-0.8 0.4-0.7 1-0.1 0.8 0 0.9-0.3 1.3-0.5 1.1-0.2-0.1-0.3-0.6-0.6-0.4-0.8-0.1 0.1 0.3 0 1.1 0.1 0.6 0.2 0.6 0 0.6-0.8 0.7-0.8 0.4-0.8 0-1.8-0.4 0.9 1.3 2.2 1.6 0.8 1.1 0.1 1-0.3 4.2 0.6 0.6 0.2 1.5 0.1 2.7 0.3 1.1 1.5 2.2 0.9 1.6-2.2-1.3-2-1.7-1-0.5-1.1-0.9-0.7-0.2-0.7 0.2-1.1 0.9-0.6 0.2-1.7 0-1.5-0.5-1-1-0.4-1.4 0-2.1-0.3-1-0.5-0.4-0.1-0.3-1-0.4-1.9-0.6-0.6-1.4-0.1-0.9 0-1.1-0.1-0.8-0.6-0.4-2.2-0.6-2.6 1.9-1.5-0.7-0.5-1.4 0.5-1.3 3.8-1-0.5-1.1-2.4-1.6-0.2-1.4 0.2-1.3 0.4-1.3 0.2-0.9-0.2-1-0.4-1.1-1.1-2.1 0.6-0.9 0.6-1.1 0.4-1.3 0.1-1.3-0.7-0.3-1.1 0.2-0.4-0.5-0.3-0.8 0.1-0.8 0.4-0.6 0.9-0.4 0-0.7-1.7-0.9-1-1.6-0.5-2.3-0.2-4.1 2.1-1.3 0.9-0.3 4.1-0.5 0.9-0.5 0.9-0.4 0.9-0.3 0.9-0.2 1 0.1 0.8 0.4 1.4 1.6 0.7 0.3 0.6 0.1 0.8 1 0.4 0.1 1.4-0.2 1.2 0.1 1-0.1 1.4-0.7 0.5 0.3 1.7 2.9 0.4 0.8 0.5 0 1.2-0.2 2.9 0.3 1 0.4 1.1 0.6 0.6 0.4 0.6 0.5 0.1 0.7 0.4 0.7 0.7 0.5 1.7 1.6 0.6 1.1 1.8 1.1z",
                        "EGY1533" : "M589.4 136.8l0.1 5.4 2.1 9.2 1.8 19.4-0.6 8.4-52.1 2.2-0.7-1.2 0.6-1.1 0.5-2 0-3.6-0.6-3.9-1.1-3.6-1.1-2.4-2.1-2.4-0.9-1.5-0.4-1.7 1.4-10.1 5.6-2.1 0.7-0.6 0.3-0.7 0.1-0.8 0.3-0.4 0.5 0 0.9 0.4 0.3 0.1 0.5-0.1 1-0.5 0.5-0.3 1.8-0.8 4-0.8 12.6-0.5 20.4-14.1 3.6 10.1z",
                        "EGY1534" : "M545.7 104.4l-1.8 1.7-2.1 1.4-0.9 1.2-0.5 1.1-0.1 1.6-1 3.4-0.2 2.6 0.6 0.7 1.4 1.1 0.8 1.7 0.6 0.9 0.8 0.8 0.8 0.9 0.8 1.3 0.6 2.3 0.7 1.5 0.7 2 0.7 0.9 0.8 0.7 17 8.6-12.6 0.5-4 0.8-1.8 0.8-0.5 0.3-1 0.5-0.5 0.1-0.3-0.1-0.9-0.4-0.5 0-0.3 0.4-0.1 0.8-0.3 0.7-0.7 0.6-5.6 2.1-0.1-0.9-0.2-0.9-0.5-0.7-0.8-0.5-3.2-0.3-1-0.6-1.8-1.8-0.9-1.6-1.5-2.2-0.3-1.1-0.1-2.7-0.2-1.5-0.6-0.6 0.3-4.2-0.1-1-0.8-1.1-2.2-1.6-0.9-1.3 1.8 0.4 0.8 0 0.8-0.4 0.8-0.7 0-0.6-0.2-0.6-0.1-0.6 0-1.1-0.1-0.3 0.8 0.1 0.6 0.4 0.3 0.6 0.2 0.1 0.5-1.1 0.3-1.3 0-0.9 0.1-0.8 0.7-1 0.8-0.4 1.4-0.3 0.6-0.5 0.1-0.5-0.1-1.3 0.4-0.3 1.3-0.5 2.3-2 0-0.6-0.5-0.7-0.1-1 0.1-0.9 0.5-0.7 0.5 0.1 0.5 0.6 0.7 0.4 1.1-0.4-0.9-1.3 0.2-2.2 2.4 0.9 1 0.8 1.1 0 1.1-0.3 0.7-0.5 1.8 0.5z",
                        "EGY1535" : "M610.2 56.2l0.1 0.6 1.4 1.8 1.2 0.7 1.4 1.1 0.8 2.9 0 1.1-0.1 1.2-0.5 1.5-2.4 3.1-1.2 3.5-1.1 2-0.5 1.7-1.1 2.3 0 3.7 1 5-0.8 2.5-1.8 3.7-5.4 7.2-2.5 2.6-2.2 1.4-2.4 0-2.1 0.4-1.3 0.4-2.1 0.3-3.6 0-0.3-0.1-3.7-1.1-0.4 0-0.9-0.2-0.4 0.5 0 1 0.3 1 1 1.2 0.9 0.7 0.8 1.1 0.7 2.4 0.3 3.4 2.5 9.9-20.4 14.1-17-8.6-0.8-0.7-0.7-0.9-0.7-2-0.7-1.5-0.6-2.3-0.8-1.3-0.8-0.9-0.8-0.8-0.6-0.9-0.8-1.7-1.4-1.1-0.6-0.7 0.2-2.6 1-3.4 0.1-1.6 0.5-1.1 0.9-1.2 2.1-1.4 1.8-1.7 1.9-2.1 0.4-2-0.1-1.8-0.2-0.9-0.5-1.7-0.4-2.7-0.7-3.3 0-1.9 0.3-1.3 0.5-1.1 0.7-0.8 0.8-0.6 1.3-0.5 1.6-0.4 3.9-0.1 0.8 0.2 0.8 0 1.3-0.2 0.8-0.2 2.7 0.3 1-0.1 1.3-0.8 0.8-1.1 2.5-2.1 0.5-0.9 0.1-0.8-0.3-1.5 0.1-1.1 0.6-0.7 0.7-0.3 0.9-0.2 0.6-0.3 1.1-0.8 0.5-1 0.4-1.1 0.8-1.6 4.3-5.1 3-5.7 0.4-0.5 0.6-0.1 1.3 0.1 0.9-0.2 0.6 0 0.9-0.4 0.7 0 0.7 0.2 0.7 0.1 1.1-0.4 1.1-0.1 3.9-0.9 0.9-0.1 0.4-0.1 2.5-2 0.7-0.2 1.7 0.1 0.8-0.4 2.5-1.6 0.1 0.5 0.5 0.5 0.8 0.3 0 0.7-0.8 0.3-0.6 0.3-0.4 0.6-0.3 0.8 0.4 0.2 0.6 0.4 0.8-0.5 0.8-0.1 0.6 0.2 0.6 0.4 0 0.6-0.6 0 0 0.8 0.8 0.7 1.1 0.5 1.1 0 1-0.7 0-0.5-1.2-0.1-0.8-0.6-0.5-0.9-0.3-1.1 1.2 0.3 1.7 0.8 0.7 0.2z m12.1-3.2l-2.1 1-2.9 0.7-7.1 0.8-0.3-0.6 1.3 0 0.4 0 0-0.7-0.3-0.1-0.2-0.4 1.1-0.8 0 0.6 0.3 0.1 0.8 0-0.3-1 0.6-0.7 0.9-0.1 0.9 1.6 1 0.4 1.3 0 1.2-0.2 1.9-1.1 1-1.7-0.3-1.7-1.5-1.4 2.1-0.1 0 0.1 0.2 5.3z",
                        "EGY1536" : "M663.9 134.7l1.5 8.8 1 19.3 0.7 1.9 0.7 1.3 0.7 0.9-16.6 11.7-0.3-0.5-1.9-1.9-1.7-0.9 0.4-0.9 0.9-0.8 0.4-0.3 0-2.7-1.1-1.8-3.3-3.3 0.7-0.5 0.3-0.5 0-0.4-0.5-0.5 0.5-0.2 0-0.3-0.5-0.2-0.7-1.1-0.5-0.4-0.1-0.4 0.1-0.3 0.6-0.3 0.6-0.1 0-0.6-0.2-0.7 0-0.5 0.2-0.8-0.5 0-1.1 2.3-0.1 1 0.3 0.7 0.4 0.5 0.4 0.7 0.1 1.3-0.6 0-0.2-1.2-0.6-0.7-1 0-1 0.6-1.3-0.5-1.6 1-1.4 1.8-0.8 1.6-0.1 1.7 0.5 1.4 1.2 1 1.8 0.4-1.4 1.2-6.9 9.7-0.4 0.7-0.8 0.9-2.4 4.4-0.4 1.5-0.1 3.9-0.5 1.6-1.1 1.3 0 0.7 0.9 0.7 0.9 1.3 0.7 1.3 0.7 2 0.9 0.9 4.1 2.8 1.1 0.8 3.7 4.5 2.6 1.5 2.3 2.4 2 2.7 0.8 1.9 0.3 2.3 0.9 3.1 1.1 2.9 1.1 1.7 0 0.6-0.3 1.6 2.2 9.2-7.9 0.1-1.5 0.2-3.4 1.1-2.3 1.4-24.9 11-1.8 0.5-1.2 0.3-6.6-0.4-11.2 1.7-3.5-1.6 5.2-72.1-0.3-4.4 0.6-8.4-1.8-19.4-2.1-9.2-0.1-5.4 29.4-1 7.1 0.5 2.4 1.6 1.1 0.5 1.5 0.4 4.2 0.7 1 0 0.4-0.1 2.4-1.1 0.4-0.2 3.2-3.1 0.6-0.3 2.7-0.8 2.5-0.3 15.6 1.1z",
                        "EGY1537" : "M619.6 36.3l-0.1 1.2-0.7-0.3-1.7-0.3-1 0.4-0.6-1.6 2.1 0.2 2 0.4z m-14.2-6.8l0.9-0.6 0.8 0.4 2 2.3 0.5 0.4 1.2 0.5 3.3 2.6 0.8 0.6-2.5-0.6-8.1-5.1 0.8 0 0.9 0.7-0.2-0.7-0.4-0.5z m-41.8-8.1l-0.3 1.1-0.2 0.5-0.4 0.7-0.6 0.6-2.8 2.1-1.4 1.7-0.2 0.3 0 0.6 0.7 0.4 3.7 0.6 0.5 0.3 0.2 0.6-0.1 0.7 0 0.6 0.3 0.5 0.5 0.3 0.6-0.2 0.6 0.1 1.1 0.9 0.5 0.3 0.6 0 0.4 0.4 0.5 1.2 0.9 0.4 0.8-0.4 0.5-0.5 0.2-0.5 0-0.4-0.3-0.9 0.2-0.7 1.6-0.7 0.9 0 0.3 0.7 0.4 1.5-0.3 0.4 0 0.7 0.5 0.7-0.3 0.5-0.7 0-0.6-0.6-0.6 0-0.3 0.6-0.3 0.7 1.6 0.8-0.2 1.1-1.1 1-1.6 0.4-1.4 0.1 0 0.4 0.4 0.8 0.1 1.3-1.5 2.1-1.4 0.4 0.2 1.2 0.3 0.9 0.6 0.4 1-0.1 4.6-3.9 2.1-1.1 3.7-1 2.5-1.7 1.2-3-0.4-0.7 1.2 0.5 0.6 0.1 0.7 0.1 0.7 0.4 0.1 0.8 0 0.9 0.3 0.4 1 0.3 1.2 0.6 1.3 0.9 0.7 0.9 0.7-1.6 0.4-0.6 0.6-0.5-0.3 0.9-0.1 0.6 0.1 0.5 0.3 0.7-1.1 0 0 0.6 1.1 0-0.5 0.4-0.1 0.3 0.1 0.6 0.4 0 0.7-0.7 0.1 0.6 0.4 0.1 0-0.7 0.6 0-0.4 1.4 0.4 0.9 0.7-0.1 0.4-1.5 1-0.1 1.2-1.4 1.6-1 1.8 0.6-1.1 0 0 0.6 1.1 0.6 0.3-0.4 0.5-0.4 0.3-0.4 1.2 0.6 0 0.6-0.5 0.8-0.1 1.2 0.9-0.4 0.1 0.6-0.1 0.5-0.3 0.4-0.6 0.3 0 0.6 0.6 0.8 0 1-1.7 1.5 0 0.6 0.9 0.1 0.7-0.2 0.4-0.5 0.3-0.7 0.5 0 0.2 1.3-2.5 1.6-0.8 0.4-1.7-0.1-0.7 0.2-2.5 2-0.4 0.1-0.9 0.1-3.9 0.9-1.1 0.1-1.1 0.4-0.7-0.1-0.7-0.2-0.7 0-0.9 0.4-0.6 0-0.9 0.2-1.3-0.1-0.6 0.1-0.4 0.5-3 5.7-4.3 5.1-0.8 1.6-0.4 1.1-0.5 1-1.1 0.8-0.6 0.3-0.9 0.2-0.7 0.3-0.6 0.7-0.1 1.1 0.3 1.5-0.1 0.8-0.5 0.9-2.5 2.1-0.8 1.1-1.3 0.8-1 0.1-2.7-0.3-0.8 0.2-1.3 0.2-0.8 0-0.8-0.2-3.9 0.1-1.6 0.4-1.3 0.5-0.8 0.6-0.7 0.8-0.5 1.1-0.3 1.3 0 1.9 0.7 3.3 0.4 2.7 0.5 1.7 0.2 0.9 0.1 1.8-0.4 2-1.9 2.1-1.8-0.5-0.7 0.5-1.1 0.3-1.1 0-1-0.8-2.4-0.9 1.2-4.3 0.2-2.6-1-4.3-0.3-2.6-0.2-0.7-0.7-0.3-0.2-0.3-0.6-2.3-0.3-4-0.8-0.9-0.3-0.6-0.3-0.7 0.4-0.4 1.9-0.6 0.6-0.3 0.3 0 0.2-0.3 0-1-0.2-0.4-0.4-0.5-1.1-0.8 0.7-0.1 1-0.5-1.1-1 0.3-0.8 0.8-0.7 0.6-0.8-0.1-1.2-0.4-0.7-0.3-0.8 0.2-1.2 0.7-1 0.9-0.2 0.9-0.2 0.9-0.5 0.2-0.5 0.5-2.7-0.1-0.7 0.1-0.5-0.3-0.2-0.4-0.1-0.8 0.4-0.8 0.1-0.8 0.2-0.7 0.5-0.9 0.3-2-0.8-0.4-0.5 0.1-0.8 0.8-2.5 0.6-4.5 1 0.3 1.3-0.8 0.7-0.5 0.9-0.5 0.7 0 0.5-0.3-0.2-0.8-1.4-1.4-0.5-0.7-0.1-0.9 0.8-2.2 0.3-1.5-0.1-2.8-0.3-1.6-0.1-1.7 0.3-4.2-0.1-3-0.7-5.8-0.2-0.9-0.4-0.9-1.1-1.3-0.4-0.5-0.2-0.8 0.1-0.8 0.1-0.9 0.3-0.5 2.1-1.7 6-3.2 2.3 1 3.4 2.7 8.5 3.9 2.7 0.7 1.2-0.1z",
                        "EGY1538" : "M647.6 58l0 0.1 0.2 8.3-23.8-13.9-1.7 0.5-0.2-5.3 0-0.1 0.2 0.1 0.4-2.9 0-1.3-0.4-1.7-1.4-1.7-0.2-0.9 1-0.7-1.2-0.7-1-0.3 0.1-1.2 3.5 0.7 1.1 0.8 0.5 0 1 0.1 0.2 1.6 0.8 1.2 1.2 0.8 2.6 0.7 0.9 0.9 1.5 2 3.5 3.4 1.5 1.1 2.3 4 2.2 2 2.4 1.5 2.8 0.9z",
                        "EGY1539" : "M606.3 28.9l-0.9 0.6-0.6-0.1-1.6-0.2-0.4-0.4-0.2-0.4-0.4-0.4-2.2-1.2-0.9-0.7-0.9 0-0.3-1.3-0.5-1.1-0.6-1-0.8-0.6 1.1 0 1-0.1-4.2-5.2-0.8-1.5-1.2-1.6-0.9-0.5-0.1 0.4-1.3-0.7-0.6 0.4-0.3 0.9-1.1-0.6 0 1-0.3 0-0.9-0.4 0 0.8-0.1 0.5-0.4 0.7 1.7 0-0.5 1.1 1.3 2.2-0.3 1.4 0.6 0 0 0.6-0.6 0 0.5 0.8 0.1 0.5-0.6 0-0.2-1.2-0.6-0.8-0.8-0.6-1.2-0.1 0.3-0.7-0.3-0.1-0.6 0.7-0.5 1.5 0.5 0 0.3-0.1 0.3-0.5 0.6 0.4 0.5 0.2 0.6 0 0 0.6-0.6 0 0 0.7 0.3 0.6 0.5 0.4 0.6 0.2 0.9 0.1-0.6 0.6-0.8 0.2-0.8-0.2-0.6-0.6-0.6 0 0.1 0.5-0.7 0.2 0.7 0.6 0.5 0.7-1.1 1.4-0.3 1.1 0.8 0.7 1.7 0 0 0.7-1.1-0.2-0.9-0.4-0.7 0-0.7 0.6-0.5 0-0.5-0.6-0.6 0.1-0.4 0.6-0.2 0.9 0.4 0.5 0.5 0.3 0.2 0.4-1.1 0.4 0 0.6 0.5 0.9-0.6 0.4-0.9 0.2-0.7 0.6-0.2 1.4 0.6 0.8 0.8 0.2 0.9-0.4-1.2 3-2.5 1.7-3.7 1-2.1 1.1-4.6 3.9-1 0.1-0.6-0.4-0.3-0.9-0.2-1.2 1.4-0.4 1.5-2.1-0.1-1.3-0.4-0.8 0-0.4 1.4-0.1 1.6-0.4 1.1-1 0.2-1.1-1.6-0.8 0.3-0.7 0.3-0.6 0.6 0 0.6 0.6 0.7 0 0.3-0.5-0.5-0.7 0-0.7 0.3-0.4-0.4-1.5-0.3-0.7-0.9 0-1.6 0.7-0.2 0.7 0.3 0.9 0 0.4-0.2 0.5-0.5 0.5-0.8 0.4-0.9-0.4-0.5-1.2-0.4-0.4-0.6 0-0.5-0.3-1.1-0.9-0.6-0.1-0.6 0.2-0.5-0.3-0.3-0.5 0-0.6 0.1-0.7-0.2-0.6-0.5-0.3-3.7-0.6-0.7-0.4 0-0.6 0.2-0.3 1.4-1.7 2.8-2.1 0.6-0.6 0.4-0.7 0.2-0.5 0.3-1.1 2.1-0.1 12.3-3.5 7.3-4.2 3-1 3.2 0.1 2.6 1.3 1.1 2.6 0.5 1.1 2.5 3.5 1.1 2.8 1.3 1.6 2.6 2.4 0.9 0.4 2 0.4 0.2 0.1z",
                        "EGY1540" : "M402.3 62.9l0 0.1 2.2 63.9 3.8 8 53.7 33.5-63.6 39.1-53.1 53.7-16.5 12.5-64.8 17-6.1 2.5-3.8 4.2-2.3 3.5-35.3 75.6-190 0.1-1.6 0 0-140.9-0.5-5.3-1.5-5.1-6.7-16.5-0.9-3.2-0.1-3.7 0.7-6.8 0-2.3-1.2-3.8-4.2-7.1-0.5-3.9 1.3-5 0.1-1.8-0.3-2.1-7.1-17.7-2.3-4.2-0.7-2.1 0-3.6 1.3-3.3 3.4-6.2 1.4-3.2 0.8-1.4 2.2-2.8 2.5-2.5 4.7-7.3 1.6-3.2 0.8-3.3 0.3-1.8 2.4-6.6 0.9-5.2 1-3.8 1.2-3.3 0.6-3.3-1.2-3.8-3.5-7.7-1.1-4.8-2.9-5.9-0.5-2-1.9-10.2-0.1-7.8-0.8-8.1 0-3.5 1-3 13.3-10.9 3-8.2 2.3-3.3 5.1-4.1-0.1 0.7 1 6.3 0.9 3.1 1.5 1.9 1.7 0.5 4.2 0.3 3.2 1.6 1.7 0 3.7-0.6 0.8 0.3 0.9 0.4 1 0.2 1.5-0.8 2-0.6 2.4-0.2 13.3-3.9 15.3-5.2 3.7-0.6 8 0.4 32.3 9.1 23.6 3.2 1.3 0.7 1.3 0.5 4.1-0.3 1.7 0.2 5.8 2.8 3.4 1.1 3.7 0 3-1.1 1.4-0.2 1.4 1 1.1 1.1 0.9 0.3 0.7 0.1 0.9 0.2 2.3 1.3 5.1 1.7 5.6 0.6 2 0.6 1.3 1 0.5-0.4 0.8-0.5 0.3-0.4 1 0.1 5.1-0.1 0.6 0.2 0.6 0.4 0.6 0.6-0.2 0.7 0.2 0.7 0.6 1.2 0.4 0.6 0.4 0.2 0.2 0.3 0.2 1.4 0.2 0.6 0.6 1 0.8 2.9 0.8 1.3 2 1.7 2.3 1.3 2.6 0.9 5.1 0.8 2 0.8 1.9 0.4 1.8-1 4.1 2.2 4.8-0.8 9.5-4.7 1.4-0.2 0.9 0.6 0.4 1.4 0.1 1.9 0.3 0.8 1.4 3.4 0.3 3.1 0.3 0.8 2.4 1.5 3.9 0.6 14.7-0.1 1 0.3 0.7 0.5 0.6 0.7 0.7 0.4 1 0.3 2.5-0.3 1.8 0.2 3.5 0.9 1.6 0.2 1.6-0.4 3.6-1.7 1.9-0.4 1.5 0.3 1.5 0.7 1.3 0.9 1 1 0.7 0.4 2.9 0 1.1 0.2 0.9 0.3 1.3 0.8 14.5 5.2 3 1.6 1.5 0.7 2 0.3 0.5 0.5 0.6 2.6 0.3 0.8 0.6 0.5 1.5 0.4 14.2 7.5 13.2-0.6 2.4-0.4 11.2-5.4 12-5.9 4.4-3.3 3.4-1.8z",
                        "EGY1541" : "M467.7 21.4l1.4 0.3 0.7 1.1 0.2 1.9-0.1 2.4 0.4 0.3 0.7 0.2 0.8 0.4 0.3 1 0.1 0.9 0.4 0.7 0.5 0.5 0.8 0.3 0-0.4 0.3-0.6 0.4-0.4 0.7 0.3 0.3 0.4 1 0.7 0.5 0.5 0.4 0.6 0.2 0.8 0.1 0.9-0.2 2-0.4 1.8-0.7 1.5-1 1 0 0.6 0.4 0.2 0.2 0.5 0.5 0 0-0.7 0.6 0 0.4 0.8 0.5 2.6 0 0.6 1.4 0 0.4-0.1 0.6-0.5 0.6-0.1 0.6 0.4 0.9 1.3 0.5 0.2 0.9 0.3 0.7 0.7 3.7 5.6 3.9 2.2 0.6 0.8 0.2 0.4 1.1 1.6 0.4 0.9 0 1-0.2 1.4 0.2 0.8 0.7 0.6 1.4 1.4 0.8 1.4-0.9 0.7 0.1 0.5 2 3 0.4 1.6-0.8 1.3-1 1.2-0.3 1 1.8 0.4 0.9 0.4 0.3 0.9-0.1 1.1-0.2 0.9-0.4 0.6-1.9 1.3 2.5-0.5 1.2-0.1 0.8 0.6-0.2 0.9-1 0.5-2.1 0.6-0.5 0.5-0.8 1.2-0.6 1.2 0.1 1.1 1.1 0.4 1.1-0.4 0.9 0.1 0.3 1.5-0.4 0.4-0.8 1.2-0.6 1.4 0.4 0.6 0.8 0.4 0.4 1 0.2 1.4 0.2 4.1 0.5 2.3 1 1.6 1.7 0.9 0 0.7-0.9 0.4-0.4 0.6-0.1 0.8 0.3 0.8 0.4 0.5 1.1-0.2 0.7 0.3-0.1 1.3-0.4 1.3-0.6 1.1-0.6 0.9 1.1 2.1 0.4 1.1 0.2 1-0.2 0.9-0.4 1.3-0.2 1.3 0.2 1.4 2.4 1.6 0.5 1.1-3.8 1-0.5 1.3 0.5 1.4-37.9 34.3-3.3 6.9-53.7-33.5-3.8-8 4.8-11.9 3.7-3.8 13.3-6.4 3-2 2.6-2.9 2.1-3.1 2.2-4.2-1.2-3.6-1.1-2.3-3.8-4.6-5.2-8.6-0.6-1.7-0.3-2.2 1.2-2.3 1.5-1.7 1-1.7 0.1-0.5-0.8-2.6-1.6-0.9-0.5-1-0.4-0.5-0.1-0.6-0.1-0.8 0.1-0.7 0.5-0.5 4.7-2.1 5.5-3.3 1-0.7 2.2-3.2 4.7-9.3 0.2-0.5 3 0.9 3 0.3-0.6 0.4-1 1.1-0.6 0.4 0 0.6 0.6 0.1-1 0.7 0.3 0.7 0.9 0.7 0.8 0.5 3.4-2-0.4 1.1 0.5 0.6 0.7 0.1 0.3-0.1 0.4-0.6 2.4-2.4 0.3 0.5 0.3 0.2 0.5-1.2 0.1-0.8 0.5 0 0 1 0.1 0.8 0.4 0.5 0.6 0.3 0.4-0.6 0.8-2.6-1.3-0.6-1.1 0.2-1.2 0.7-1.5 0.3 0-0.6 1.1 0 0-0.6-1.3 0.4-4.8 0.2 0-0.6 3-0.8 2.9-1.6 5-4.6 1.8-2.9 1.1-3.8 0.3-4.1-0.7-3.3 0.6 0 0.4 1.9 0.7 1.7 1.2 1.3 1.6 0.3z",
                        "EGY1542" : "M525.2 215.2l-3.3 3.3-3.2 6.3-3.3 3.7-1.5 2.9-2.6 3.9-5.5 6.1-6.9 3.6-34 9.6-3.9 0.3-5.5-3.9-35.5-6.6 38.1-37.1 6-4.9 14.9-8.8 17.1-7.9 17.1-2.1 3.9 2.9 2.2 2.4 5.9 26.3z",
                        "EGY1543" : "M443.2 36.7l-0.2 0.5-4.7 9.3-2.2 3.2-1 0.7-5.5 3.3-4.7 2.1-0.5 0.5-0.1 0.7 0.1 0.8 0.1 0.6 0.4 0.5 0.5 1 1.6 0.9 0.8 2.6-0.1 0.5-1 1.7-1.5 1.7-1.2 2.3 0.3 2.2 0.6 1.7 5.2 8.6 3.8 4.6 1.1 2.3 1.2 3.6-2.2 4.2-2.1 3.1-2.6 2.9-3 2-13.3 6.4-3.7 3.8-4.8 11.9-2.2-63.9 0-0.1 0.4-0.2 0.6-0.9 0.7-0.7 12-8.9 1.3-2.5 2.2 0.6 2.4-1.2 3.8-3.4-0.7-1-0.3 0-0.7 0.4 0.4-1 0.7-0.6 0.6-0.1 0.5 1 0.6 0 0.9-1 3.8-3.4 1.2-0.8 1-0.5 1.7-2.3 0.6-0.5 1.2-0.2 0.6-0.6 0.6-0.6 0.7-0.6-0.6-0.2 0.1-0.5 2.2-1.2-0.2 2.7 2.3 1.9 0.3 0.1z",
                        "EGY1544" : "M528.7 142.2l1.8 1.8 1 0.6 3.2 0.3 0.8 0.5 0.5 0.7 0.2 0.9 0.1 0.9-1.4 10.1 0.4 1.7 0.9 1.5 2.1 2.4 1.1 2.4 1.1 3.6 0.6 3.9 0 3.6-0.5 2-0.6 1.1 0.7 1.2 52.1-2.2 0.3 4.4-5.2 72.1-30.1-9.1-1.5-0.8-2.5-1.5-1.6-1.2-3.2-3.4-1-1.3-0.3-0.6-1.2-2.7-0.5-0.8-0.6-0.7-1.7-1.5-6-7.4 0.2-1 0.1-0.8 0-1-0.2-1-0.4-0.9-0.8-1.4-0.6-0.7-0.6-0.6-0.8-0.5-1.2-0.6-2.4-0.8-2.1-0.3-3.7 0.1-5.9-26.3-2.2-2.4-3.9-2.9-17.1 2.1-17.1 7.9-14.9 8.8-6 4.9-38.1 37.1-3.3 23.6-2.1 7.2-13.2 34.9-10.4 13.8-12.4 9.2-37.8 20-5.8 4.4-4.1 6.2-5.8 12.8-108.6 0 35.3-75.6 2.3-3.5 3.8-4.2 6.1-2.5 64.8-17 16.5-12.5 53.1-53.7 63.6-39.1 3.3-6.9 37.9-34.3 1.5 0.7 2.6-1.9 2.2 0.6 0.6 0.4 0.1 0.8 0 1.1 0.1 0.9 0.6 1.4 1.9 0.6 1 0.4 0.1 0.3 0.5 0.4 0.3 1 0 2.1 0.4 1.4 1 1 1.5 0.5 1.7 0 0.6-0.2 1.1-0.9 0.7-0.2 0.7 0.2 1.1 0.9 1 0.5 2 1.7 2.2 1.3z",
                        "EGY1545" : "M512.3 279.3l-2.6 22.7-0.4 1.9-0.5 1.1-4 6.8-2.3 6.2-0.5 2.1-0.2 1.7 0.1 1 0.8 4.2 0.4 4 0.1 1 0.4 1.1 4.4 8.7 1.3 3.7 0.4 2.5 0.7 8.8 0.5 2.1 1.9 4.9 0.4 1.8 0.3 2.8 0.1 2.2-0.1 1.5-1.4 8.8-8.8 1-0.8-0.1-4.8-1.9-1.3 0.1-2.6 0.5-1.6 0.1-2.2-1 0.4-1.1 0.9-2-166.2 0 5.8-12.8 4.1-6.2 5.8-4.4 37.8-20 12.4-9.2 10.4-13.8 13.2-34.9 83.4-2 1.4 1.5 12.9 4.6z",
                        "EGY1546" : "M537.7 224.7l-0.3 4 0.3 3.7-0.1 1.3-0.6 1.8-1 1.9-1.4 3.9-1 2-1.2 1.8-3.6 3.9-2.3 3.1-4.7 7.6-5.5 7.4-1.8 3.2-1.5 4.3-0.6 2.8-0.1 1.9-12.9-4.6-1.4-1.5-83.4 2 2.1-7.2 3.3-23.6 35.5 6.6 5.5 3.9 3.9-0.3 34-9.6 6.9-3.6 5.5-6.1 2.6-3.9 1.5-2.9 3.3-3.7 3.2-6.3 3.3-3.3 3.7-0.1 2.1 0.3 2.4 0.8 1.2 0.6 0.8 0.5 0.6 0.6 0.6 0.7 0.8 1.4 0.4 0.9 0.2 1 0 1-0.1 0.8-0.2 1z",
                        "EGY1547" : "M545.5 13.2l-6 3.2-2.1 1.7-0.3 0.5-0.1 0.9-0.1 0.8 0.2 0.8 0.4 0.5 1.1 1.3 0.4 0.9 0.2 0.9 0.7 5.8 0.1 3-0.3 4.2 0.1 1.7 0.3 1.6 0.1 2.8-0.3 1.5-0.8 2.2 0.1 0.9 0.5 0.7 1.4 1.4 0.2 0.8-0.5 0.3-0.7 0-0.9 0.5-0.7 0.5-1.3 0.8-1.7-1.6-0.5-0.3-0.8-0.3-0.9-0.1-0.9 0.1-0.9 0.5-1.8 1.6-0.9 0-1.8-0.8-4.4-0.2-0.6 0.8-0.1 0.9 0 1 0.1 1.6-0.1 0.5-0.2 0.8-0.4 0.8-0.4 1.9-0.8 0.8-1.3 0.6-5.9 0.4-0.7 0.2-0.8 0.5-0.9 0.5-0.4 0.4 0.1 0.3-0.8 0.5-1.3-0.2-1.2 0.2-1.4 0.5-1 0.2-4.8-1.7-0.8-0.4-0.6 0.1-0.8 1.9-0.8-1.4-1.4-1.4-0.7-0.6-0.2-0.8 0.2-1.4 0-1-0.4-0.9-1.1-1.6-0.2-0.4-0.6-0.8-3.9-2.2-3.7-5.6-0.7-0.7-0.9-0.3-0.5-0.2-0.9-1.3-0.6-0.4-0.6 0.1-0.6 0.5-0.4 0.1-1.4 0 0-0.6-0.5-2.6-0.4-0.8-0.6 0 0 0.7-0.5 0-0.2-0.5-0.4-0.2 0-0.6 1-1 0.7-1.5 0.4-1.8 0.2-2-0.1-0.9-0.2-0.8-0.4-0.6-0.5-0.5-1-0.7-0.3-0.4-0.7-0.3-0.4 0.4-0.3 0.6 0 0.4-0.8-0.3-0.5-0.5-0.4-0.7-0.1-0.9-0.3-1-0.8-0.4-0.7-0.2-0.4-0.3 0.1-2.4-0.2-1.9-0.7-1.1-1.4-0.3-2.3-1.7-1.2-2.8 0.5-1.7 3 1.7 2.2 1.7 2.5 1 3 0.3 3.5-0.4 11.5-3.1 24.3-8.7 0 0.7-1.2 0.1-7.6 2.9-6.3 3.6-4.3 2.1-3.5 2.4-0.5 0.2-1.1 0.2-0.6 0.2-3.1 2.2-1.5 0.5-3.2 0.3-0.7 0.4-0.4 0-1.2 1.9 0 0.7 1.7 0.4 0.5 0.1 0.6-0.5 0.5 0 1.3 0.7 2.2-0.1 2.3-0.7 1-0.9 0.7-1.6 1.6 0.5 1.7 1.4 1 1.3 0.5 0 0.6-1.6 1.2-1.7 1.5-1.3 1.3-0.6 0.7-0.3 0.9 0.4 1.1 0.7 1.2 0.5 0.7-0.1 1.1-0.3 1.1-0.1 1 0.5-0.6 0.2 0.1 0.5 1.1 0.3 1.4-0.5 1.3-0.9 1.1-0.9-0.5-0.2 0-0.4 0.3-0.3 0.2-0.5 2.8 1.3 0.6 0.7 0.7-0.6 0.6-0.8 0.9-1.9-0.5-0.8 0.3-0.7 1.3-1.1 0.3-0.6-0.1-0.9 0.4-0.5 0.5-0.1 3 0.3 0.8 0.3 1.3 0.9 0.2 0.3 0 0.5 0.2 0.3 0.7 0.2 0.7-0.2 0.5-0.5 0.3-0.6-1.5-0.8 0.6-0.3 0.5-0.2 0.5 0.1-1.6-2.2-3.3-2.5-3.8-1.6-3.7-0.2 0.7-0.4 2.1-0.8 6.9-1 2.6 0.3 7.5 2.4 10.6 4.8z",
                        "EGY1548" : "M557.3 887.9l-4.9 0 4.6-13.5 0.1-2.2-0.8-1.9-1.8-1.8-1.5-0.8-1.5-0.2-1.6 0.3-1.5 0.8-2.2 2.3-3.6 7.6-0.8-1.3-0.8-0.9-3.6-2.6-0.8-0.8-0.8-0.9-0.4-0.9-0.2-1 0.3-1.2 0.6-1.3 1.3-1.9 1-1.1 1.1-0.9 2.1-1 2-0.6 2-0.3 4.2-0.2 1.9-0.3 2.1-0.7 1.9-0.9 1.4-0.8 2.8-2.3 5.8-7.3 0.7-1.4 0.5-1.4 0.6-2.8 0.1-0.6-0.6-4.8-1.3-5.2-0.3-2 0-0.9 0.3-1.3 0.6-1.4 1.5-2.3 1.1-1.3 1.2-1 1.1-0.5 1.1-0.4 1-0.2 1-0.1 1.9 0 7 1.9 0.9 0.1 0.9-0.1 26-12.4 2.3-0.7 1.1-0.2 1 0.1 1 0.4 1.8 1.2 3.7 3.1 1 0.4 1 0.3 1.2 0 2.2-0.5 1 0 0.9 0.2 0.9 0.6 0.7 0.7 1 1.7 0.7 0.8 0.8 0.2 0.9-0.3 0.8-0.9 1.6-3.4 0.6-0.9 0.7-0.9 0.9-1.7 0.7-2.4 1-5 0.8-2.5 0.9-1.6 0.7-1 0.3-0.5 0.8-1.7 2.4-8 4-8.9 2.1-2.8 7.1-7.8 0.8-1.2 0.5-1.2 0.3-1.6-0.1-1.5-0.6-1.6-0.8-0.4-1-0.2-11 1.7-8.2-0.3-3.3-0.7-0.9-0.3-0.9-0.5-0.7-1-0.3-1.4 0.5-2.2 0.3-1.2 0.7-1.6 0.7-2.3 1.1-6.8 1-3.9 0.5-0.9 2-2.9 1.5-1.8 1.8-1.8 1-0.6 0.9-0.5 1-0.4 2-0.5 10.1-1.4 1-0.4 0.9-0.6 0.5-1 0.1-1.1-0.7-1.7-0.8-0.9-0.9-0.7-1.9-0.9-3.7-2.1-0.9-0.8-0.7-0.9-0.5-1.2-0.1-1.5 0.2-2.6 0.6-2.8 0.5-1.1 0.7-0.9 0.7-0.6 0.9-0.4 1-0.4 1.9-0.3 5.2 0.2 2-0.3 1-0.3 1-0.5 0.9-0.6 0.9-0.8 0.7-1 0.3-0.6 0.7-0.8 0.2-0.9 0.8-3.2 0-1.7-1.1-3.7-0.1-1.1 0.1-2.9 0.2-1 0-2.1 0.6-4.5 0-1.1-0.7-6.2 0.2-5 0.3-1.9 0-1.2-0.2-0.2 0.5-3.6 3-7.3 0.8-3.4-0.3-1.3 0-0.5-0.6-3.3-1.6-4.8-3.5-7.3-0.6-1.6-0.3-1.2-0.9-9.3-1.2-3.4-0.9-1.9-1.4-2.1-1.8-2-2.8-2.3-6.7-3.8 1.4-1.2 0.7-0.4 0.8-0.6 0.4-0.8 0.3-1.3 0-4.8 0.6-2.1 16.6 12.7 3 4 2.8 4.8 1.1 2.7 0.6 2.6 0.8 5.3 0.2 12.1 0.5 3.2 0.5 1.3 8.8 18.5 0.1 0.7-0.1 1.7-0.6 2.3-0.3 0.8-1 1.9-1.3 2-6.7 8.8-0.7 1.6-1.7 7.1-0.8 6.1 2.3 15.3 0.8 2.1 1.9 3.6 2.2 6.1 0.7 1.6 1.3 1.7 1.6 1.4 1.7 1.2 0.9 0.7 0.9 1.1 1 1.9 0.3 1.3 0.1 1.2-0.1 1.4 0 1.7 0.5 4.7-0.1 1.5-0.4 0.9-1.7 2.7-0.2 1.5 0.1 2.3 1.8 8.3 0.5 1.4 2.3 3.6 0.9 2 0.3 1.4 0.1 1.3-0.1 0.9-0.7 2.3-2.9 7.5-0.4 0.9-0.6 0.8-2.5 2-0.8 0.9-0.5 1.1-1.2 3-0.4 0.9-0.6 0.9-1.6 1.8-0.5 1.2 0.2 1.1 0.5 1 0.9 0.7 5.6 3.5 4.8 1.8 1 0.5 0.8 0.7 0.7 0.9 1.1 2 0.7 0.8 1.6 1.5 0.7 0.9 0.5 0.9 3.4 11.6 0.2 2.3-0.3 1-0.7 0.4-0.8 0-0.9-0.3-0.9-0.4-5.3-4-6.5-6.8-2-1.2-1.9-0.6-2-0.2-6.7 1.1-0.8 0-0.9-0.1-0.9-0.3-0.9-0.4-1.9-1.5-3.6-3.8-0.9-0.9-1-0.6-0.8-0.2-0.8 0.1-0.7 0.6-0.4 0.9-0.9 2.7-0.5 0.8-1.6 1.6-0.7 1.2 0 1.2 0.5 3.8-0.1 2.6-0.3 1.6-0.5 1.2-1.1 1.8-2.1 2.8-10.6 9.6-2.6 2.9-3 2.7-1.4 0.9-1.6 0.9-3.7 1.2-3.9 0.6-4.6-0.1-1.1-0.2-2-0.6-2.1-1-0.8-0.6-0.8-0.6-3.4-3.9-3.7-3-0.9-0.6-0.9-0.4-0.9-0.1-0.9 0.3-0.8 0.6-0.6 0.9-0.9 1.9-5.3 15-1.4 2.3-1.4 1.8-1.1 1.3-3.3 2.4-0.9 0.5-1 0.4-1 0.2-2.8 0-1 0.2-1.1 0.4-1 0.9-0.6 0.9-1.1 1.9-1.4 1.8-1 0.8-16.9 8-1.8 1-1.8 1.5-1.9 2.2-2.3 4.4-0.1 0.4z",
                        "EGY1549" : "M512.1 380.9l-0.3 8.1 0.1 2.7 0.3 1.3 0.7 2.6 0.6 1.2 0.5 1 0.8 1 0.8 0.7 7.1 4.2 8.3 3.5 5.2 1.6 1.2 0.6 1.2 0.9 1.8 1.6 1 1.3 0.8 1.4 1.3 3.7 0.6 1.4 0.6 0.8 0.6 0.5 1.9 1.2 3.3 2.8 5.2 5.3 1.1 1.4 1.9 3.2 8.7 18.4-3.2 0.4-1-0.3-1.2-0.5-0.9-0.8-0.8-1-0.7-1.1-1.3-2.9-0.6-1-0.6-0.8-1.4-1.4-1.1-0.4-0.9 0-0.5 0.3-0.6 0.6-0.8 1.1-0.6 1-0.5 0.7-0.8 0.8-0.9 0.7-7.6 4.2-10.3-20.8-1-1.5-3.8-4.2-1.6-1.2-1.3-1-7.5-3.1-4-2.3-10.9-10.3-1.2-1.6-1.4-2-7.6-16.3-0.9-2.9-0.2-2.5 0.3-3.6 2.2 1 1.6-0.1 2.6-0.5 1.3-0.1 4.8 1.9 0.8 0.1 8.8-1z",
                        "EGY1550" : "M490 379.6l-0.3 3.6 0.2 2.5 0.9 2.9 7.6 16.3 1.4 2 1.2 1.6 10.9 10.3 4 2.3 7.5 3.1 1.3 1 1.6 1.2 3.8 4.2 1 1.5 10.3 20.8 11.3 14.1 7.8 6.6 34.2 43 12.9 12.3 0.9 0.6 1.4 0.8 2 1 1.2 0.4 1.5 0.3 2.3 0.1 4-0.7 7.2-2.1 18.8-8.8 2.3-0.6 3.7-0.5 1.4 0.1 1.2 0.2 0.9 0.4 0.8 0.6 0.8 0.8 0.7 0.9 0.6 0.9 0.3 1 0.3 1.8 0 1.9-0.2 1.2-0.3 1-0.8 1.8-3.4 5.9-0.5 1.1-0.3 1-0.6 4.3-0.5 2-0.4 1-0.5 0.9-0.6 0.9-1.6 1.8-11.2 8.9-2.4 2.5-1.2 1.8-0.4 0.9-0.2 0.9-0.1 1.9 0.1 1.4 2.8 11 2.2 13 1.2 3.2 0.8 1.4 0.8 1.2 1.7 1.8 7.7 6 6.7 3.8 2.8 2.3 1.8 2 1.4 2.1 0.9 1.9 1.2 3.4 0.9 9.3 0.3 1.2 0.6 1.6 3.5 7.3 1.6 4.8 0.6 3.3 0 0.5 0.3 1.3-0.8 3.4-3 7.3-0.5 3.6 0.2 0.2 0 1.2-0.3 1.9-0.2 5 0.7 6.2 0 1.1-0.6 4.5 0 2.1-0.2 1-0.1 2.9 0.1 1.1 1.1 3.7 0 1.7-0.8 3.2-0.2 0.9-0.7 0.8-0.3 0.6-0.7 1-0.9 0.8-0.9 0.6-1 0.5-1 0.3-2 0.3-5.2-0.2-1.9 0.3-1 0.4-0.9 0.4-0.7 0.6-0.7 0.9-0.5 1.1-0.6 2.8-0.2 2.6 0.1 1.5 0.5 1.2 0.7 0.9 0.9 0.8 3.7 2.1 1.9 0.9 0.9 0.7 0.8 0.9 0.7 1.7-0.1 1.1-0.5 1-0.9 0.6-1 0.4-10.1 1.4-2 0.5-1 0.4-0.9 0.5-1 0.6-1.8 1.8-1.5 1.8-2 2.9-0.5 0.9-1 3.9-1.1 6.8-0.7 2.3-0.7 1.6-0.3 1.2-0.5 2.2 0.3 1.4 0.7 1 0.9 0.5 0.9 0.3 3.3 0.7 8.2 0.3 11-1.7 1 0.2 0.8 0.4 0.6 1.6 0.1 1.5-0.3 1.6-0.5 1.2-0.8 1.2-7.1 7.8-2.1 2.8-4 8.9-2.4 8-0.8 1.7-0.3 0.5-0.7 1-0.9 1.6-0.8 2.5-1 5-0.7 2.4-0.9 1.7-0.7 0.9-0.6 0.9-1.6 3.4-0.8 0.9-0.9 0.3-0.8-0.2-0.7-0.8-1-1.7-0.7-0.7-0.9-0.6-0.9-0.2-1 0-2.2 0.5-1.2 0-1-0.3-1-0.4-3.7-3.1-1.8-1.2-1-0.4-1-0.1-1.1 0.2-2.3 0.7-26 12.4-0.9 0.1-0.9-0.1-7-1.9-1.9 0-1 0.1-1 0.2-1.1 0.4-1.1 0.5-1.2 1-1.1 1.3-1.5 2.3-0.6 1.4-0.3 1.3 0 0.9 0.3 2 1.3 5.2 0.6 4.8-0.1 0.6-0.6 2.8-0.5 1.4-0.7 1.4-5.8 7.3-2.8 2.3-1.4 0.8-1.9 0.9-2.1 0.7-1.9 0.3-4.2 0.2-2 0.3-2 0.6-2.1 1-1.1 0.9-1 1.1-1.3 1.9-0.6 1.3-0.3 1.2 0.2 1 0.4 0.9 0.8 0.9 0.8 0.8 3.6 2.6 0.8 0.9 0.8 1.3-4.4 8.8-1 0.7-11.1 0-15.9 0-39.8 0-8 0-31.8 0-15.9 0-23.9 0-7.9 0-31.8 0-15.9 0-39.8 0-8 0-15.9 0-15.9-0.1-39.8 0-7.9 0-31.8 0-15.9 0-23.9 0-7.9 0-16 0-15.9 0-23.8 0-8 0-31.8 0-8 0 0-511.3 1.6 0 190-0.1 108.6 0 166.2 0-0.9 2-0.4 1.1z",
                        "EGY1551" : "M656.2 595.6l-0.6 2.1 0 4.8-0.3 1.3-0.4 0.8-0.8 0.6-0.7 0.4-1.4 1.2-7.7-6-1.7-1.8-0.8-1.2-0.8-1.4-1.2-3.2-2.2-13-2.8-11-0.1-1.4 0.1-1.9 0.2-0.9 0.4-0.9 1.2-1.8 2.4-2.5 11.2-8.9 1.6-1.8 0.6-0.9 0.5-0.9 0.4-1 0.5-2 0.6-4.3 0.3-1 0.5-1.1 3.4-5.9 0.8-1.8 0.3-1 0.2-1.2 0-1.9-0.3-1.8-0.3-1-0.6-0.9-0.7-0.9-0.8-0.8-0.8-0.6-0.9-0.4-1.2-0.2-1.4-0.1-3.7 0.5-2.3 0.6-18.8 8.8-7.2 2.1-4 0.7-2.3-0.1-1.5-0.3-1.2-0.4-2-1-1.4-0.8-0.9-0.6-12.9-12.3 3.2-3 0.9-0.6 0.9-0.4 4.6-0.6 1.3-0.4 1-0.7 1.9-2.3 0.4-0.4 0.9-0.4 1 0.2 1 1 2.4 4 1.6 1.9 1.8 1.4 1.9 1.1 1.2 0 0.8-0.1 2.2-2.4 2.5-0.5 16.5-8 4.2-0.8 2.4-0.2 5.2 0.4 6.4 1.8 1.6 0.9 2 1.4 2.8 2.6 3.2 4.4 1.2 2.1 0.8 2 1.2 4.3 0.9 6.7 0.1 3.2-0.1 2.1-0.5 2.5-0.7 2.4-4.2 8.7-1.5 2.1-1.8 2.1-7.9 7.1-5.4 6-1.3 1.8-0.8 1.8-1 3-0.1 1.3 0.1 4.8 1.4 6.8 0.9 2.6 1.1 1.9 0.7 0.9 2.6 2.5z m-3.8-38.9l0.8-1.3 0.1-0.7-1.6-0.8-2 3.9 1 0.2 1.1 0.1 0.6-1.4z",
                        "EGY1552" : "M567.4 453.3l13.8 9.6 3.6 3.5 1.2 3 1.9 3.3 2.2 2.9 0.8 1.7 0.5 1.4 0.4 4.1 0.2 1 1.2 2.5 2 3 1.3 1.7 1.1 1.2 1.5 1 2.2 1.2 2.3 0.9 5.4 1.2 1 0.4 1.3 0.8 0.8 1.1 0.8 1.1 2.2 4.1 8.6 10.9-2.2 2.4-0.8 0.1-1.2 0-1.9-1.1-1.8-1.4-1.6-1.9-2.4-4-1-1-1-0.2-0.9 0.4-0.4 0.4-1.9 2.3-1 0.7-1.3 0.4-4.6 0.6-0.9 0.4-0.9 0.6-3.2 3-34.2-43-7.8-6.6-11.3-14.1 7.6-4.2 0.9-0.7 0.8-0.8 0.5-0.7 0.6-1 0.8-1.1 0.6-0.6 0.5-0.3 0.9 0 1.1 0.4 1.4 1.4 0.6 0.8 0.6 1 1.3 2.9 0.7 1.1 0.8 1 0.9 0.8 1.2 0.5 1 0.3 3.2-0.4z",
                        "EGY1556" : "M762.3 462.6l0 2.1-1.1-1.1-2.8-6.4 1.2 0 0.5 0 1.6 3.5 0.6 1.9z m0.3-71.5l1.8 0.7 0.5 1.6 0.3 1.6 1 1.1 0 0.6-1.6-0.3-2-2.2-1.7-0.6-0.8-0.5-0.8-0.9-0.8-0.6-1.9 0.9-0.7-0.7-0.6-1-0.3-1 0.4-0.6 0.6-0.4 0.6-0.2 0.7 0 1.8 0.2 1.4 0.9 1.1 1 1 0.4z m-174.7-135.4l3.5 1.6 11.2-1.7 6.6 0.4 1.2-0.3 1.8-0.5 24.9-11 2.3-1.4 3.4-1.1 1.5-0.2 7.9-0.1 0.2 1 0.1 2-0.4 0.8-0.9 0.7-0.4 1.1-0.9 0.4-0.3 0.8 0.7 1-0.5 2.8-0.1 3.3 0.5 1 2.6 2.6 0.8 1.2 0.3 0.9 0 1.9 0.3 1 1.9 2 0.3 0.2 3.4 4.8 2.9 0.6 1.8 1.9 1.2 2.9 3.6 13.8 0.3 1.9 0.9 0.3 3.9 2.3 1.9 1.9 1 1.2 0.8 1.7 0.8 0.3 0.9 0.2 0.8 0.4 0.2 0.6 0.6 1.9 2.3 4.5 0.8 0.7-0.1 0.5-0.5 0.1 3.6 3 1.5 2-0.1 2 0.7 0.5 0.5 1 0.4 1.2 0.2 0.8 0.3 0.3 1.8 2.6 3.9 4.2 1 2 0.8 0.5 0.9 0.4 0.7 0.5 0.4 1.2-0.1 1 0.3 0.7 1.4 0.3 1.4 0.7 2.7 3.3 1.8 1.1-0.2 0.5 0.2 0.8 0 0.5-0.2 0.8 0.6 0.6 1 0.2 0.8-0.2 0.7 1.3 1.8 0.8 3.7 1 5.8 5.4 1.9 3.9 1 0.9 0.5 1 1.8 4.2 0.2 1.1 0 0.6 0.4 0.7 0.3 1.8 0.4 0.7 0 0.6-1.7 0-0.9-2.1-1.9-1.1-2.2-0.9-1.7-1-0.6 0-0.5 1.4-0.2 0.7 0.2 0.7 0.5 1 1.6 1.6 0.8 1.2 0.4 1.4 0.5 0.7 1.2-0.3 1.2-0.6 0.5 0.2-0.1 1.2-0.3 1.4-0.6 1.2-0.7 1 0.8 0.9 1.8 1.4 0.5 0.1 0.2 0.4 0.8 1.7 0.4 0.5 0 0.6-0.9-0.7-1.9-2.5-0.6 0 0 0.7 0.3 0.5 0.3 0.8-0.6 0-0.5-1.8-1.4 0.2-1.6 1.3-0.9 1.5 1.9 1 1.4 1.9 2.3 4.1-0.3 0.6-0.3 0.7-0.1 0.9 0.1 1 1.4 1 3.5 1.6 1.3 1.2 0.2 0.8 0.1 2 0.3 0.9 0.5 0.8 1.4 1.5 0.6 0.9 0.5 1.9 0.6 4.1 0.5 1.2 2.8 2.6 3.1 2.2 3.5 1.7 1.6 1.1 1 1.6 0.2 0.9-0.2 3.5-0.1 0.3-0.8 0.7-0.2 0.3 0.1 0.5 0.4 0.8 0.1 0.6 0.1 2 0.3 1.6 0.9 1.2 1.5 1.1 1.4 1.3 1.5 2.1 0.6 1.5-1.2-0.2 0 1.5 0.5 1.3 1.7 2.2 0.7 1.4 1 2.8 0.8 1.2 1 0.8 1.2 0.7 1 0.7 0.4 1 0.6 2.9 0 1.4-0.6 1-1.3 0.1-0.9-0.8-0.8-0.4-0.9 1.8-0.2 1.2 0 1.6 0.2 1.6 0.3 1.2 0 2.4-1.6 5.6 0.8 2.6 1.1 1 2.7 0.8 1.2 0.8 0.9 1.2 0.8 2.9 2.7 3.5 1.1 2.5 2.8 8.1 1.2 2.4 1.7 2.5 1.1 2.3 2 3 6.9 15.9 3.2 4.8 3 7.8 6.5 9 0.6 1.1 0.8 2.6 5.5 8.2 2.9 3.3 0.7 0.9 7.1 14.1 1.1 4.3 2 3.9 0.9 4.6 1.5 2.5 3.5 4.5 0.5 1.1 0.8 2.7 0.5 1.2 2.4 3.8 1 3.8 3.8 6.6 7 12.2 0.3 2.9 0.9 2.5 2.9 3.5 0.3 1.7 0.1 3.3 0.2 1.7 0.5 1.4 0.6 1 1 0.8 1.3 0.8 2.1 2 1.4 2.6 1.9 7.1 0.4 1.1 1.5 2.4 1.5 2.8 1.2 1.1 0 1.4-1.3 2.8 0 2.5 3.4 1.3 4 7.6 11.1 8.5 1.7 2.1 3 8.7 2.2 2.4 3.1 4.5 1.4-0.2-0.6-1.3-0.8-1.2 0.9-0.2 1.6 1.8 2.3 0.9 3 3.1 1.1 2.5 0.2 2.6 2.5 1.5 2.6-0.4 2 0.5 2.1 0.7 1.7 0.9 1.3 1.3 1.7 4 1.5 2-0.6 0.8-1.2-1.7-1.7-1.8-1.2-0.1-2.9 1.4-1.3 0.6-3.1-1.3-1.6-0.3-1.1 0.1-1.2-0.2-1.5-0.6-0.6-0.7-0.9-1.2-0.9-0.2 0-0.5-1.3-0.6-1.7-0.4-0.8 0.5-1.1 2.1-0.6 2.7 0.6 4.2-1.3 6.5 0.7 2.3 1.5 0.3 0.7 1.1-0.1 1.3-0.3 0.7 0.2 1.4 0.2 3.1-0.4 3.7-0.2 7.7-0.1 1.4-0.8 2.5-0.2 1.4 0.3 1.3 0.8 1.3 1.7 2.5 1.4 2.6 0.5 1.4 0.3 1.5 0 4.2 0.6 4.3 0.8 3.3 0.5 2.9 3.8 6.5 1.2 2.5 1.6 3.3 1.1 8.1 0.6 1.5 1.6 3 3.4 4.3 2.2 1.2-1-1.4-2.3-4.1 1.6 0.1 1 0.8 0.8 1.3 0.5 1.5 0.9 4.4 0.2 0.7 1.4 0.9 0.6 1 0.6 1.1 1.1 1.3 1.4 1.9 3.2 2.4 2.9 1.2 1.5 0.5 0.3 0.4 1 0.7 1.1 0.6 1.2 0.4 4.6 0.3 6.6 1.3 6.3 2.1 2.3 1.4 4 3.8 1.3 2.2 0.4 4.1 1.4 2.7 2.5 2.1 2.5 2 2.5 1.1-0.3-1.4 0.5 0 1.7 2-0.4 2.5 1.4 3.6 5.5 2.5 2.7 1.6 1.8 1.2 5 4.2 7.3 7.1 1.6 0.8 1.2-0.1 0.3-0.5 0.2-0.6 0.3-0.3 0.6 0.2 1.4 0.9 0.7 0.6 0.4 0.6 1.2 2.6 0.7 1.1 1.2 1.1 3.2 2 1.9 0.7 0.3 3.2-0.1 1.1-0.5 0.9-0.7 1-19.1 0-38 0-38 0-19.1 0-57 0-38 0-76.1 0-19 0-133.9 0-2.2 0 0.1-0.4 2.3-4.4 1.9-2.2 1.8-1.5 1.8-1 16.9-8 1-0.8 1.4-1.8 1.1-1.9 0.6-0.9 1-0.9 1.1-0.4 1-0.2 2.8 0 1-0.2 1-0.4 0.9-0.5 3.3-2.4 1.1-1.3 1.4-1.8 1.4-2.3 5.3-15 0.9-1.9 0.6-0.9 0.8-0.6 0.9-0.3 0.9 0.1 0.9 0.4 0.9 0.6 3.7 3 3.4 3.9 0.8 0.6 0.8 0.6 2.1 1 2 0.6 1.1 0.2 4.6 0.1 3.9-0.6 3.7-1.2 1.6-0.9 1.4-0.9 3-2.7 2.6-2.9 10.6-9.6 2.1-2.8 1.1-1.8 0.5-1.2 0.3-1.6 0.1-2.6-0.5-3.8 0-1.2 0.7-1.2 1.6-1.6 0.5-0.8 0.9-2.7 0.4-0.9 0.7-0.6 0.8-0.1 0.8 0.2 1 0.6 0.9 0.9 3.6 3.8 1.9 1.5 0.9 0.4 0.9 0.3 0.9 0.1 0.8 0 6.7-1.1 2 0.2 1.9 0.6 2 1.2 6.5 6.8 5.3 4 0.9 0.4 0.9 0.3 0.8 0 0.7-0.4 0.3-1-0.2-2.3-3.4-11.6-0.5-0.9-0.7-0.9-1.6-1.5-0.7-0.8-1.1-2-0.7-0.9-0.8-0.7-1-0.5-4.8-1.8-5.6-3.5-0.9-0.7-0.5-1-0.2-1.1 0.5-1.2 1.6-1.8 0.6-0.9 0.4-0.9 1.2-3 0.5-1.1 0.8-0.9 2.5-2 0.6-0.8 0.4-0.9 2.9-7.5 0.7-2.3 0.1-0.9-0.1-1.3-0.3-1.4-0.9-2-2.3-3.6-0.5-1.4-1.8-8.3-0.1-2.3 0.2-1.5 1.7-2.7 0.4-0.9 0.1-1.5-0.5-4.7 0-1.7 0.1-1.4-0.1-1.2-0.3-1.3-1-1.9-0.9-1.1-0.9-0.7-1.7-1.2-1.6-1.4-1.3-1.7-0.7-1.6-2.2-6.1-1.9-3.6-0.8-2.1-2.3-15.3 0.8-6.1 1.7-7.1 0.7-1.6 6.7-8.8 1.3-2 1-1.9 0.3-0.8 0.6-2.3 0.1-1.7-0.1-0.7-8.8-18.5-0.5-1.3-0.5-3.2-0.2-12.1-0.8-5.3-0.6-2.6-1.1-2.7-2.8-4.8-3-4-16.6-12.7-2.6-2.5-0.7-0.9-1.1-1.9-0.9-2.6-1.4-6.8-0.1-4.8 0.1-1.3 1-3 0.8-1.8 1.3-1.8 5.4-6 7.9-7.1 1.8-2.1 1.5-2.1 4.2-8.7 0.7-2.4 0.5-2.5 0.1-2.1-0.1-3.2-0.9-6.7-1.2-4.3-0.8-2-1.2-2.1-3.2-4.4-2.8-2.6-2-1.4-1.6-0.9-6.4-1.8-5.2-0.4-2.4 0.2-4.2 0.8-16.5 8-2.5 0.5-8.6-10.9-2.2-4.1-0.8-1.1-0.8-1.1-1.3-0.8-1-0.4-5.4-1.2-2.3-0.9-2.2-1.2-1.5-1-1.1-1.2-1.3-1.7-2-3-1.2-2.5-0.2-1-0.4-4.1-0.5-1.4-0.8-1.7-2.2-2.9-1.9-3.3-1.2-3-3.6-3.5-13.8-9.6-8.7-18.4-1.9-3.2-1.1-1.4-5.2-5.3-3.3-2.8-1.9-1.2-0.6-0.5-0.6-0.8-0.6-1.4-1.3-3.7-0.8-1.4-1-1.3-1.8-1.6-1.2-0.9-1.2-0.6-5.2-1.6-8.3-3.5-7.1-4.2-0.8-0.7-0.8-1-0.5-1-0.6-1.2-0.7-2.6-0.3-1.3-0.1-2.7 0.3-8.1 1.4-8.8 0.1-1.5-0.1-2.2-0.3-2.8-0.4-1.8-1.9-4.9-0.5-2.1-0.7-8.8-0.4-2.5-1.3-3.7-4.4-8.7-0.4-1.1-0.1-1-0.4-4-0.8-4.2-0.1-1 0.2-1.7 0.5-2.1 2.3-6.2 4-6.8 0.5-1.1 0.4-1.9 2.6-22.7 0.1-1.9 0.6-2.8 1.5-4.3 1.8-3.2 5.5-7.4 4.7-7.6 2.3-3.1 3.6-3.9 1.2-1.8 1-2 1.4-3.9 1-1.9 0.6-1.8 0.1-1.3-0.3-3.7 0.3-4 6 7.4 1.7 1.5 0.6 0.7 0.5 0.8 1.2 2.7 0.3 0.6 1 1.3 3.2 3.4 1.6 1.2 2.5 1.5 1.5 0.8 30.1 9.1z",
                        "EGY1557" : "M821.9 353.3l-2.3 1-1.9-0.7-1.6-1.4 1.7-2.6 4.1 0.1 0 3.6z m-15.4-7.2l-2.1 0.5-0.9 0.4-0.3 1 0.7 0.8 1.4 0.1 2.3-0.4 1.1-0.3 0.3 0.2 0.4 0.6 0.5 0.9 2.9 2.6 0 0.6-3.2 0.3-2.8-0.2-2.4-1-1.8-2.3 0.1-1.2-0.2-1.8-0.4-0.8 0.4-0.5 0.1 0.5 0.3-0.7 0.4-0.5 0.5-0.4 0.5-0.3 1.5 0.8 0.4 0.5 0.3 0.6z m-154.6-167.5l16.6-11.7 22.5-1.1 52.1 9.3 20.9 11.3 16.6 6.3 9.5 5.1 10.2 3.7 34.1 5.3-0.8 0.5-0.7 0.5-0.6 0.7-0.6 0.8-0.4 1.1-0.3 1-0.4 0.8-1.1 0.4 0.7 0.2-0.1 0.5-0.7 0.3-0.5 0.5-0.2 0.5 0.3 0.6-0.8 0.1-0.3 0.3 0 0.3 0.5 0.5-0.9 0.9-1.9 3-0.4 0.4-0.9 0.5-0.4 0.3-0.6 1.1-0.4 0.5-0.7 0.5 0 0.5 0.8 1.3-0.3 1.4-0.7 1.3-0.4 1.2 0 4.8-0.4 1.1-1 0.9-0.9 0.7-0.4 0.5-0.1 1.3-0.3 1.5-0.6 1.5-0.7 1.2 0.2 1-0.2 5.7 0.1 0.9 0.9 1.2 0.1 1.1-0.2 1.1-0.6 0.5-0.8 0.3-1.8 1.2-0.3 0.5-0.2 1.2 0 0.6 0.4 1.9 0.1 5.5-2.1 1.6 0 0.6 0.2 0.8 0.2 1.3 0 1.4-0.4 1.1 0.5 0.7 0.5 1.1-0.7 0.5-0.1 0.5 0.3 1.3-0.2 1-0.4 0.6-0.4 0.5-0.1 0.4-0.5 1.7-1.9 2.7-1.1 4.3-3.3 5-1.1 2.6-0.1 0.7-0.4-0.1 1 2.9-0.9 1.8-1.9 1.4-1.6 1.6 0.3 0.2 0.2 0.5-1.1 0.5-0.6 1.3-0.8 4.1-0.3 1-1 1.6-0.1 0-0.3 1.1-1.1 2.3-0.3 1.1 0.1 1.6 0.2 1.2 0.4 1 0.4 1 0 0.6-0.6 1.6 0.7 1.3 1 1.3 0.8 1.5 0.7 0.8 0.3 0.5 0 0.6-0.6 1-0.1 1.2-0.7 3.2-1 2.6 1.4 2.6-1.3 6.5 0.6 0.7-2.1 0.4-0.7 0.3-0.3 0.5-0.2 0.8-0.4 0.8-1 0.7-0.5 1.3-0.7 0.3-0.6 0.1-1.2 0.4-0.8 0.1 0.2 0.5 0.4 0.2-0.6 1.4-0.8 2.8-0.8 0.9-0.6 0-0.2-0.5-0.7-0.3-0.5-0.4-0.6 0.6-0.6 2-0.7 1.1 0.7 1.1-1.1 1-1.6 0.7-1.1 0.3-1 0 0.4 1.4 0.2 0.6 3 0 0 0.6-0.6 0 0 0.6 0.4 0.4 0.3 0.4 0.4 1.1-0.8-0.4-0.1 0.3 0.4 0.1 0 0.7-0.6 0-0.4-0.8-1.5-2-1.5-1.6-0.7-0.6-0.8-0.4-1.3-0.4-7.8-0.9-2-1.3-5.5-6.6-0.4-0.3-0.7 0-4.7-4.3-1-0.5-1.1-0.1-0.9 0.7-1.1-2.4-0.6 0.5-0.7-0.9-2.9-2.4-0.9-0.5-0.3-0.4-0.3-0.8-0.2-0.3-0.6-0.5-0.6-0.3-1.3-0.3 0.1-2.3-4-2.4 0-1.6-1.2-1-1.4-2-0.9-2 0.2-1.3-0.8-0.5-0.2-0.3-0.2-0.5-0.5 0 0 0.7-0.6 0-0.3-0.5-0.7-0.8-0.1-0.3-1.3-4.6-0.4-0.6-0.6 0.4-0.6-1.3-1.9-2.9-0.8-1.5-10.7-6.4-0.5-1-0.4-0.1-1.9-3.4-1.6-1.5-0.9-1.1 0-0.5-5.2-3.9-0.9-0.9-0.4-0.7-0.2-0.7-0.7-1.2-0.9-1.1-0.9-0.5 0.5-0.6 0 0.6 0.6 0-0.6-3-1.4-0.2-0.7 1.2 1.6 1.4-1.4-0.5-0.9-1.2-0.4-1.7-0.4-3.8-0.5-1.5-1.5-2.9 0.9-1.8 1-4.3 0.9-2.1-1-1.3-0.5-0.7-0.4-1.9-0.6-0.4-0.8-0.3-0.6-0.5-0.5-1.8-0.3-4.1-0.3-1.2 0-0.6 0.7-0.8 0.1-0.9-0.3-2.1-0.2-0.5-0.3-1.3-0.1-1.4 0.4-0.7 0.6-0.6-0.6-1.3-1-1-0.5 0.1-0.1-1-0.5-0.7-0.7-0.3-0.8 0.3-0.9-1.1-2.2-1.2-0.9-0.9-1-2.3-0.1-0.6-0.3-0.5-1.2-0.9-0.2-0.5-0.3-0.1-1.4-2.1-1.1-0.7-0.4-1-0.1-0.3-3.7-3.8-1.3-0.4-1.8-1-1.8-1.3-1-1.1-0.5-1.5-0.4-2-0.5-1.6-1.1-0.8-0.8-0.3-0.5-0.7-1.7-4-0.1-0.1 0.3-3.5-0.3-1.6-2.2-1-4-2.9 0.6 0-0.3-0.7-0.3-0.3-1.1-0.3 0.4-0.4 0.2-0.3-0.1-0.6-0.5 0-0.4 0.8-0.1 0.7 0.1 0.6 0.4 0.5-1.1 0 0.6-3.5 0.2-4.4-1-3.8-2.6-1.8 0-0.6 0.5-1.2 0-1.3-0.3-1.4-0.2-1.3 0.2-1.4 0.7-1.9 0.2-0.9-0.1-1.6-0.2-1-0.3-0.8-0.5-0.8-2-2.5-0.2-1.1-0.1-0.1z",
                        "EGY1558" : "M679.3 55.9l0.1 0.9-0.8-0.7-0.3-0.5 0.1-0.5 0.5 0.2 0.4 0.6z m36.4-8.5l3.5 2.9-1.7-1.2-12.8-5.6-2.3-0.4 2.5 0.1 4.2 2 1.9 0.5 2.5 0.5 2.2 1.2z m-26.8-6.5l12.9 1.6-0.6 0.4-1 0-2.5-0.5-4.9-0.7-2.8 0.8-1.3-0.3-2.1 0.8-9.9 5.3-1.7 1.4 0.9-1.4 1.9-1 1.6-0.8 1-0.6 1.1-0.8 4.3-2 0.9-0.9 2.2-1.3z m145.5 165.9l-34.1-5.3-10.2-3.7-9.5-5.1-16.6-6.3-20.9-11.3-52.1-9.3-22.5 1.1-0.7-0.9-0.7-1.3-0.7-1.9-1-19.3-1.5-8.8-4.4-11.2-7.5-12.1-0.1-0.4-0.3-1.2-0.3-2-0.2-8.4-3.3-33-0.2-8.3 0-0.1 0.2 0 3.5 0.1 3.5-0.4 6.1-1.6 7.2-3.6 1.4-1.1 3.4-1.7 0.9-0.7 0.6 0 0 0.7-2.6 1-4.6 3.5-2.6 0.7-4.5 2.1-7 1.9 3.9 0 0 0.6-1.1 0.7 2.5-0.1 0.9-0.3 0.5-0.9 0.5 0 0.1 0.5 1.1 0.1 5-3.3 4.2-1.3 0.9-0.7 0.5 0 0.3 0.5 1.2 0.3-0.3 0.5-0.6 0.1 0 0.6 0.9-0.3 1.9-1 0-0.7-2.2 0 0-0.6 1.1-0.4 1.3 0.3 1.3 1 0.8 1.1 0.2 0.5 0.3 1.5-1.1 0 2.7 0.9 1.2 0 1.1-0.9 0-0.8-0.7-0.4-0.4-0.2 0-0.6 3.1-0.8 0.8-0.6-0.4-0.7 0.2-0.7 0.4-0.8 0.4-1-0.6 0-0.5 0.6-1.7 1.3-0.5 0.7 0 0.3 0.5 0.3-1.1 0.3-1.9 0-1.9-0.3-1.3-0.6 2.5-0.2 1.4-1.5 1-1.9 1.3-1.6 1-0.5 2-0.4 0.9-0.4 1.6-1.5 1-0.5 1.4 0 0 0.6-2.3 0 0 0.6 1 0.8 2.9 3.9 0.9 1.6-0.3 0.5-1.1 0.3-1.1 0.8-0.2-0.6-0.5 0 0 0.6 1.4 1 0.7 1.2 0 1.5-0.9 1.6 2.9-1.2 1.6-0.3 1 0.1 0.6-0.1 1.1 0.1 0-0.5-1.1-0.8-0.6 0 0 0.8-0.5 0 0-0.8 4.4-1.7 1.2-0.9 0.6 0-0.6 0.7 0.6 0.7 0.6-0.5 0.6-0.1 0.6 0.4 0.4 0.8 0.6 0 0-0.8 0-0.9-0.1-0.2 1.2-0.1-0.8-0.4-0.8 0.1-0.8-0.1-0.9-0.2 8.9-0.7-0.7-1.7 1-0.4 1.3-0.1 0-1.7 0.9 0.5 0.3 0.2 0.6 0 1.1-0.3 3.2 1.7 1.5 0.5 6 0.6 1.6 0.7 0-0.6 1.9 0.5 2.7-0.1 16.8-4.5 15.8-6.2 12.5-8.2 2 3.7 0.5 1.6 2.3 7.2 5.8 18.1 3.1 8.3 4.2 11 5 13.4 1.8 7.5 0.2 3.9 0.5 1.7 1.3 1.7 0.8 1.2 0 1.3-0.8 2.8-0.2 1.7 0.2 1.1 0.6 0.9 4.4 3.9 0.9 1.4 2.8 7.8 4.8 13.9 3.5 10.2 0 1.2 0.5 5.1 3.6 9.9 3.2 8.8 2.1 9.7-0.1 6.5 0.5 2.3 1.9 3.8 0.7 1.4-0.1 0z",
                        "EGY5494" : "M652.4 556.7l-0.6 1.4-1.1-0.1-1-0.2 2-3.9 1.6 0.8-0.1 0.7-0.8 1.3z"
                    }
                }
            }
        }
    );

    return Mapael;

}));