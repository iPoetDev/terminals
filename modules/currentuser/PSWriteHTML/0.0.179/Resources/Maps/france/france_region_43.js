/*!
*
* Jquery Mapael - Dynamic maps jQuery plugin (based on raphael.js)
* Requires jQuery and Mapael
*
* Map of Franche-Comte for Mapael
* Equirectangular projection
* 
* @author CCM Benchmark Group
* @source http://fr.m.wikipedia.org/wiki/Fichier:France_location_map-Departements.svg
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
                france_region_43 : {
                    width : 86.249969,
                    height : 116.49937,
                    getCoords : function (lat, lon) {
                        var xfactor = 45.48385;
                        var xoffset = -239.98095;
                        var x = (lon * xfactor) + xoffset;
                        
                        var yfactor = -65.97284;
                        var yoffset = 3168.2364;
                        var y = (lat * yfactor) + yoffset;
                        return {x : x, y : y};
                    },
                    elems : {
                        "department-70" : "m 39.82,0.14 c -0.5,0.38 -1.04,0.73 -1.72,0.55 -1.48,0.04 -3.08,1.07 -3.19,2.63 -0.41,0.51 -0.63,1.31 -1.48,1.13 -0.99,-0.03 -1.1,1.59 -2.11,1.39 -0.84,-0.16 -0.13,-1.14 0.18,-1.48 0.77,-0.39 0.19,-1.5 -0.54,-1.17 -0.8,0.34 -0.49,1.42 -0.9,1.96 -0.48,0.05 -0.71,0.4 -0.76,0.83 -0.67,0.53 -0.12,1.4 -0.43,2.03 -0.59,0.41 -1.54,-0.5 -1.95,0.36 -0.18,0.69 -0.68,1.21 -0.89,1.88 -0.08,0.53 0.42,1.34 -0.49,1.31 -0.71,0.51 -1.02,-0.46 -1.7,-0.45 -0.8,-0.31 -1.57,0.42 -1.38,1.24 0.3,0.66 -0.2,1.37 -0.89,1.27 -0.64,-0.22 -1.72,-0.44 -1.88,0.49 -0.08,0.8 -0.67,1.95 0.02,2.59 0.5,0.03 1.08,0.19 1,0.83 0.18,0.65 -0.18,1.15 -0.68,1.49 -0.14,0.47 -0.07,0.99 -0.36,1.45 0.18,0.61 0.74,1.57 -0.06,2 -0.59,0.07 -1.14,0.27 -1.67,0.52 -0.81,0.21 -1.66,0.19 -2.5,0.27 -0.4,-0.63 -0.3,-1.67 -0.92,-2.11 -1.14,0.21 -1.34,2.24 -2.69,1.95 -0.7,-0.04 -1.48,-0.88 -2.05,-0.1 -0.83,0.65 -1.85,0.25 -2.75,0.14 -0.54,0.63 -0.09,1.77 -0.8,2.38 -0.62,0.62 -1.28,2.05 -0.28,2.62 1.11,-0.1 1.08,-1.84 2.07,-2.17 0.97,0.35 1.77,1.29 2.23,2.2 0.43,0.85 -0,1.83 0.59,2.59 0.26,0.81 0,2.08 -0.95,2.24 -0.73,0.55 -0.75,1.99 -1.75,2.17 -0.58,-0.39 -1.67,-0.51 -1.95,0.33 -0.32,0.55 1,0.46 0.41,0.89 -0.4,0.14 -1.41,1.05 -0.51,1.14 0.43,-0.18 1.22,-0.59 1.32,0.15 0.2,0.38 1.28,0.15 0.9,0.74 -0.39,0.62 -0.3,1.51 0.07,2.09 -0.13,0.6 -0.21,1.67 0.72,1.52 0.59,-0.19 1.21,-0.63 1.8,-0.11 -0.05,1.1 -0.31,2.28 0.01,3.39 -0.02,0.61 -1.3,0.89 -0.85,1.46 1.14,-0.03 2.23,0.71 2.63,1.78 0.39,0.41 1.06,0.52 1.11,1.18 0.47,0.13 0.64,0.57 0.95,0.9 0.56,0.12 1.21,-0.23 1.8,0.01 0.69,0.35 1.27,-0.1 1.72,-0.57 0.55,-0.1 0.85,-0.87 1.48,-0.41 0.7,0.25 1.45,0.29 2.17,0.45 0.55,-0.19 0.86,-0.82 1.49,-0.86 0.88,-0.9 2.2,-1.14 3.34,-1.5 0.43,-0.44 0.79,-1.02 1.45,-1.06 0.25,-0.43 0.95,0.08 1.03,-0.55 0.02,-0.75 1.56,0.13 1.29,-0.86 -0.11,-0.67 0.92,-0.18 1.23,-0.13 0.64,0.07 1.35,1.17 1.95,0.51 -0.07,-0.44 0.31,-0.53 0.6,-0.25 1,0.81 1.46,-1.05 2.41,-0.98 0.78,0.12 1.07,-0.61 1.09,-1.24 0.32,-0.19 1.28,0.23 1.14,-0.5 -0.22,-0.47 0.42,-1.37 0.87,-1.01 0.48,0.88 2.19,0.22 2.17,-0.71 -0.23,-0.32 -0.34,-0.77 0.22,-0.75 0.67,0.08 0.8,-0.76 1.23,-0.98 0.46,0.47 1.05,0.65 1.4,-0.01 0.42,0.41 1.18,0.24 1.03,-0.46 -0.05,-0.54 0.48,-0.58 0.84,-0.63 0.79,-0.7 0.78,-1.94 1.13,-2.78 0.63,0.18 1.11,-0.26 1.26,-0.82 0.42,-0.51 1.22,-0.55 1.81,-0.72 0.58,0.2 1.12,-0.02 1.41,-0.51 0.91,0.01 1.98,0.06 2.77,0.55 0.3,0.49 0.5,1.45 1.14,0.63 0.51,-0.66 0.81,-0.38 1.21,0.13 0.52,0.28 1.05,-0.66 1.45,0.05 0.67,0.53 1.86,0.09 1.67,-0.88 0.04,-0.43 -0.1,-0.94 -0.41,-1.15 0.08,-0.5 0.48,-1.33 1.06,-0.75 0.54,0.24 0.86,0.85 1.57,0.64 0.87,-0.01 1.49,-0.97 1.61,-1.73 -0.17,-0.36 -0.81,-1.21 -0.12,-1.3 0.31,0.55 1.24,0.06 1.35,0.8 0.39,0.52 1.11,0.62 1.63,0.33 0.96,0.16 1.43,1.86 2.54,1.38 0.61,-0.62 0.9,-1.51 1.46,-2.18 -0.16,-0.72 -1.09,-1.17 -1.15,-1.99 -0.01,-0.54 -0.81,-0.65 -0.49,-1.17 0.25,-0.53 1.18,-0.97 0.74,-1.65 -0.72,-0.27 -0.73,-1.37 -0.76,-2.04 0.13,-0.92 -0.39,-1.74 -0.6,-2.59 -0.99,-1.75 0.36,-3.74 1.61,-4.95 0.45,-0.46 1.42,-1.23 0.57,-1.81 -0.54,-0.47 -1.2,-0.93 -1.14,-1.74 -0.68,-0.8 -1.95,-0.83 -2.76,-1.52 -1.06,-0.76 -2.1,-1.52 -3.29,-2.09 -0.94,-0.44 -0.78,-1.77 -1.72,-2.27 -0.73,-0.97 -2.03,-0.32 -2.52,0.53 -0.46,0.86 -1.02,1.76 -2.1,1.85 -0.66,0.11 -1.25,0.64 -1.82,0.75 -0.68,-0.67 -0.79,-1.64 -1.23,-2.41 -0.52,-0.59 -0.84,-1.54 -1.83,-1.37 -0.34,-0.38 -0.56,-1.01 -1.21,-1 -1.34,-0.45 -2.59,1 -3.95,0.4 -1.39,-0.35 -2.14,1.51 -3.51,1.27 -0.29,0.34 -0.93,0.24 -0.72,-0.3 0,-0.94 -1.08,-0.97 -1.73,-1.17 -0.36,-0.27 -1.19,-0.74 -0.53,-1.17 0.37,-0.5 0.17,-1.07 -0.13,-1.5 -0.01,-0.66 -0.46,-1.65 -1.19,-1.72 z",
                        "department-25" : "m 64.7,29.99 c -0.68,0.19 0.28,0.83 -0.21,1.22 -0.41,0.99 -1.79,1.98 -2.76,1.17 -0.31,-0.67 -1.49,-0.55 -1.23,0.28 0.56,1 0.06,2.85 -1.35,2.44 -0.33,-0.46 -0.85,-0.6 -1.31,-0.25 -0.58,-0.2 -1.43,-0.79 -1.83,0.05 -0.11,0.21 -0.29,0.91 -0.5,0.37 -0.16,-0.69 -0.37,-1.56 -1.24,-1.58 -0.76,-0.23 -2.03,-0.61 -2.29,0.42 -0.6,-0.05 -1.28,-0.43 -1.8,0.11 -0.82,0.01 -1.07,0.89 -1.6,1.32 -0.57,-0.23 -0.79,0.35 -0.72,0.83 -0.21,0.67 -0.7,1.23 -0.79,1.94 -0.32,0.24 -1.02,-0.22 -0.99,0.47 0.06,0.77 -1.05,0.98 -0.97,1.75 -0.63,-0.1 -1.24,-1.3 -1.88,-0.8 0.09,0.7 -1.46,0.31 -0.93,1.01 0.3,0.03 0.75,0.36 0.21,0.45 -0.76,0.42 -1.45,1.49 -2.44,0.9 -0.31,-0.38 -0.9,-0.29 -0.94,0.27 -0.01,0.52 0.72,1.11 -0.03,1.45 -0.54,0.4 -0.58,-1.24 -1.14,-0.38 -0.01,0.85 -0.88,1.29 -1.62,1.35 -0.68,0.15 -0.87,1.18 -1.66,0.89 -0.49,-0.18 -0.84,0.11 -1.13,0.39 -0.95,-0.01 -1.65,-1.16 -2.67,-0.9 -0.36,0.18 0.16,0.96 -0.4,0.8 -0.54,-0.17 -1.31,0.05 -0.97,0.75 0.07,0.58 -0.57,0.35 -0.78,0.06 -0.39,-0.12 -0.63,0.33 -1.03,0.3 -0.62,0.68 -1.47,1.09 -2.38,1.29 -1.02,0.19 -1.66,1.03 -2.57,1.4 -0.44,0.46 -1.03,0.75 -1.61,0.34 -0.53,-0.28 -0.86,0.37 -0.46,0.74 0.72,1 0.35,2.85 1.75,3.3 0.6,-0.19 0.7,0.75 1.29,0.79 0.68,0.14 0.27,1.08 0.94,1.24 0.52,0.12 0.88,0.47 0.8,1.02 -0.02,0.66 1.08,1.13 0.29,1.64 -0.58,0.68 -0.66,1.6 -1.31,2.23 -0.14,0.51 -1.07,0.35 -0.75,1.04 0.05,0.67 0.76,1.71 0.17,2.26 -0.74,0.27 -1.4,0.8 -1.45,1.66 -0.1,0.93 1.15,0.6 1.61,0.31 0.87,-0.16 0.44,-1.16 0.91,-1.61 0.76,-0.57 0.71,0.72 0.74,1.16 -0.06,0.84 0.89,0.84 1.4,1.18 0.68,0.16 1.45,0.12 1.93,0.68 0.73,0.27 0.97,-0.74 1.36,-1.03 0.17,0.66 -0.64,1.89 0.32,2.13 0.44,0.03 0.83,-0.59 1.11,-0.05 0.85,-0.04 1.55,0.99 1.01,1.71 -0.72,0.24 -0.32,0.94 0.24,1.06 0.37,0.22 1.09,0.56 0.55,1.03 -0.64,0.58 -0.36,1.5 0.39,1.8 0.97,0.12 0.01,1.65 0.96,1.69 0.72,-0.29 0.5,0.68 0.37,1.07 0.17,0.88 1.37,0.27 1.79,-0.06 0.69,0.04 0.84,1.02 1.61,0.86 0.61,0.47 1.22,1.08 1.94,1.46 0.57,0.55 0.94,1.31 1.58,1.83 0.45,0.6 1.1,1.2 1.26,1.91 -0.47,0.44 -1.02,0.86 -1.16,1.52 -1.43,1.21 -3.1,2.2 -4.52,3.43 -0.83,0.58 0.37,1.5 0.56,2.13 0.52,0.55 0.18,1.26 -0.45,1.52 -0.68,0.33 -1.1,0.94 -1.21,1.63 -0.4,0.54 0.61,1.06 0.87,1.48 0.86,0.71 1.6,1.8 2.69,2.11 0.72,-0.57 -0.91,-1.34 -0.16,-2.01 2.57,-2.2 4.87,-4.71 7.54,-6.78 1.18,-0.72 2.87,-0.98 3.53,-2.3 0.72,-0.25 0.86,-1.43 1.78,-1.31 0.95,-0.34 1.61,-1.37 1.94,-2.23 -0.46,-0.62 -1.49,-1.23 -0.9,-2.11 0.27,-1.36 1.42,-2.44 1.16,-3.92 0.09,-1.28 -0.75,-2.33 -1.29,-3.41 0.83,-0.96 1.59,-2.24 2.76,-2.74 1.98,-0.18 3.86,-1.04 5.7,-1.76 1.35,-0.84 2.12,-2.46 3.72,-2.92 0.67,-0.39 0.36,-1.25 -0.07,-1.68 -0.16,-0.92 0.52,-1.86 1.48,-1.97 0.91,-0.24 0.38,-1.62 1.42,-1.75 1.39,-0.66 3.03,-1.51 3.62,-3.01 0.65,-1.39 2.01,-2.43 3.16,-3.41 1,-0.56 2.06,-1.42 1.84,-2.7 0.1,-0.93 -0.58,-2.43 0.86,-2.35 0.73,-0.25 2.35,-0.54 1.97,-1.65 -0.14,-0.41 0.8,-0.4 1.03,-0.57 1.14,-0.24 1.26,-1.81 0.28,-2.35 -0.63,-0.6 -1.48,-0.53 -2.19,-0.16 -1.65,0.42 -3.39,0.39 -5.09,0.47 -0.19,-1.3 1.24,-1.83 1.77,-2.81 0.31,-0.28 1.03,-0.14 0.87,-0.79 0.06,-1.48 -0.15,-3.23 -1.33,-4.22 -0.06,-0.53 -0.26,-1.42 0.25,-1.76 0.29,-0.12 0.7,-0.15 0.83,0.18 0.64,-0.09 0.72,-1.27 -0.02,-1.37 -0.61,-0.24 -1.37,-0.58 -1.16,-1.38 -0.12,-0.87 -1.32,-1.24 -2,-0.74 -0.86,0.15 -2.04,0.43 -2.59,-0.42 -0.81,-0.01 -0.87,1.82 -1.79,1.14 -0.81,-0.21 -1.13,-1.25 -1.93,-1.36 -0.26,0.24 -0.5,0.46 -0.85,0.15 -0.56,-0.16 -0.95,-0.55 -1.29,-0.94 -0.14,-0.06 -0.29,-0.06 -0.44,-0.05 z",
                        "department-39" : "m 11.97,47.92 c -0.5,0.12 -0.3,0.81 -0.68,1 -0.33,-0.08 -0.69,0.06 -0.69,0.47 -0.21,0.81 -0.21,1.69 -0.2,2.5 -0.34,0.42 -0.25,0.96 -0.25,1.46 -0.21,0.64 -1.28,0.61 -1.33,1.3 0.32,0.32 0.52,0.75 0.37,1.23 -0.06,0.72 -0.48,1.3 -0.76,1.92 0.02,0.53 -0.42,0.92 -0.9,1.03 -0.47,0.27 -0.38,0.81 -0.49,1.24 -0.4,0.43 -0.54,0.97 -0.68,1.51 -0.38,1.1 -1.74,0.99 -2.71,1.14 -0.62,0.06 -0.86,0.74 -1.26,1.06 -0.81,0.38 -1.46,1.3 -1.37,2.21 0.51,0.32 1.29,0.33 1.69,0.77 0.1,0.4 -0.53,0.23 -0.64,0.58 -0.2,0.63 -1.12,0.24 -1.31,0.9 -0.38,0.49 -1.06,0.92 -0.64,1.63 0.08,0.48 0.37,1.07 -0.1,1.44 -0.11,0.51 0.63,1.03 1.01,0.53 0.34,-0.36 1.07,-0.2 1.29,0.2 0.14,0.84 0.22,1.73 0.84,2.39 0.18,0.24 0.1,0.87 0.57,0.65 0.31,-0.22 0.66,-0.32 0.86,0.11 0.59,0.37 1.28,-0.88 1.89,-0.23 0.45,0.38 -0.01,1.23 0.54,1.62 0.57,0.67 1.72,0.2 2.26,0.84 0.04,0.6 0.36,1.17 0.04,1.77 -0.86,0.04 -1.76,0.17 -2.55,-0.2 -0.75,0.18 -1.53,0.29 -2.17,0.79 -0.33,0.39 -0.83,-0.33 -1.09,0.19 -0.28,0.64 0.08,1.7 0.89,1.62 0.55,0.16 0.89,0.56 1.26,0.94 0.45,0.11 0.57,0.58 0.24,0.9 -0.38,0.56 -1.23,1.23 -0.86,1.98 0.38,0.31 1.27,-0.01 1.24,0.72 -0.03,0.57 0.42,0.91 0.64,1.36 0.15,0.56 -0.92,1.16 -0.02,1.45 0.55,0.28 1.17,1.07 0.64,1.63 -0.06,0.63 1.24,0.89 0.7,1.53 -0.4,0.59 -0.96,1.13 -1.61,1.43 0.37,0.59 0.66,1.11 0.18,1.79 -0.29,0.58 -1.53,-0.11 -1.83,0.49 0.3,0.63 -0.27,1.15 -0.16,1.79 0.05,0.64 -0.18,1.43 0.12,1.97 1.01,0.09 1.52,1.15 2.49,1.3 0.18,0.73 0.19,1.78 -0.68,2.05 -0.42,0.28 -1.09,-0.12 -1.3,0.5 -0.58,0.25 -1.32,-0.07 -1.96,0.01 -0.49,-0.04 -0.44,0.57 -0.86,0.72 -0.33,0.54 0.68,1.22 0.06,1.7 -0.42,0.49 -0.13,1.16 0.44,1.34 0.57,0.29 1.24,0.29 1.69,0.81 0.28,0.25 0.94,0.64 0.43,1.03 -0.73,0.44 0.3,0.72 0.22,1.26 0.18,0.71 0.91,1.21 1.51,1.54 0.41,-0.03 0.15,-0.82 0.59,-0.82 0.5,0.51 0.29,1.55 0.92,1.95 0.47,0.01 0.91,-0.8 1.23,-0.18 0.57,0.45 0,1.23 -0.17,1.79 -0.62,0.68 0.01,2.01 0.98,1.69 0.36,-0.09 0.75,-0.34 1.04,0.02 1.13,0.21 2.06,-0.77 2.51,-1.7 0.49,-0.18 1.29,0.07 1.54,-0.6 0.39,-0.7 0.4,-1.72 1.3,-1.99 0.38,-0.07 0.59,-0.79 1,-0.6 0.31,0.32 -0.25,1.1 0.46,1.07 0.58,-0.04 1.05,0.36 1.34,0.78 0.47,0.28 1.39,0.05 1.4,0.84 0.16,0.77 -0.1,1.63 0.2,2.35 0.5,0.27 1.09,-0.26 1.64,-0.18 1.44,-0.18 2.91,0.58 4.31,0.18 0.36,-0.4 1.11,-0.11 1.3,-0.73 0.27,-0.45 0.73,-0.78 1.27,-0.74 0.56,-0.4 0.08,-1.64 0.9,-1.76 0.65,0.44 0.99,-0.52 1.25,-0.94 0.66,-1.09 1.13,-2.43 2.33,-3.06 0.97,-0.67 1.48,-1.77 2.27,-2.58 0.82,-0.48 1.8,-1.52 1.15,-2.51 -0.46,-0.69 -0.08,-1.49 0.48,-1.97 0.89,-0.94 1.16,-2.24 1.86,-3.29 0.34,-0.55 1.12,-0.85 1.25,-1.51 -0.09,-0.47 -0.69,-0.73 -0.96,-0.25 -0.47,0.46 -0.85,-0.41 -1.25,-0.6 -0.95,-0.91 -2.02,-1.78 -2.81,-2.83 0.24,-0.34 0.41,-0.71 0.49,-1.12 0.49,-0.61 1.41,-0.84 1.78,-1.53 -0.25,-0.93 -1,-1.7 -1.23,-2.6 1.28,-1.07 2.63,-2.14 4.05,-3.07 0.57,-0.24 0.89,-0.78 1.05,-1.35 0.25,-0.41 1.16,-0.62 0.78,-1.22 -0.7,-1.19 -1.83,-2.07 -2.62,-3.17 -0.52,-0.52 -1.37,-0.69 -1.68,-1.37 -0.31,-0.31 -0.82,0.29 -0.98,-0.25 -0.14,-0.54 -0.81,-0.88 -1.22,-0.39 -0.35,0.62 -1.09,0.17 -1.5,-0.08 -0.08,-0.38 0.28,-1.17 -0.42,-1.11 -0.78,-0.22 -0.08,-1.44 -0.78,-1.79 -0.47,-0.34 -1.2,-0.91 -0.79,-1.56 0.36,-0.46 0.58,-0.99 -0.11,-1.27 -0.25,-0.29 -0.88,-0.37 -0.98,-0.68 0.41,-0.47 1.17,-1.08 0.53,-1.71 -0.33,-0.34 -0.85,-0.28 -1.24,-0.48 -0.43,0.03 -0.94,0.3 -1.22,-0.2 -0.31,-0.22 2.2e-4,-0.97 -0.57,-0.84 -0.36,0.24 -0.76,0.19 -1.01,-0.17 -0.39,-0.33 -1.12,-0.56 -1.48,-0.16 -0.39,-0.4 -0.92,-0.67 -1.44,-0.84 -0.41,-0.53 0.18,-1.52 -0.43,-1.91 -0.63,0.11 -0.24,1.02 -0.67,1.36 -0.28,0.48 -0.94,0.3 -1.26,0.74 -0.78,0.13 -1.49,-0.85 -0.91,-1.49 0.18,-0.45 -0.91,-1.12 -0.09,-1.28 0.44,-0.01 0.72,0.72 1.18,0.34 0.88,-0.38 0.32,-1.49 0.08,-2.12 -0.24,-0.49 0.03,-1.15 0.62,-1.11 0.25,-0.25 0.33,-0.64 0.66,-0.87 0.29,-0.61 0.47,-1.36 0.99,-1.8 -0.09,-0.45 -0.55,-0.78 -0.51,-1.3 -0.02,-0.45 -0.21,-1.01 -0.78,-0.87 -0.72,0.16 -0.25,-0.84 -0.69,-1.12 -0.34,-0.33 -1.06,-0.21 -1.08,-0.81 -0.24,-0.37 -0.75,0.29 -0.84,-0.25 -0.48,-0.7 -0.99,-1.4 -0.98,-2.29 -0.32,-0.79 -0.61,-1.85 -1.49,-2.17 -0.49,-0.02 -0.82,0.44 -1.27,0.54 -0.36,0.67 -1.37,0.88 -2.02,0.46 -0.51,-0.25 -1,0.1 -1.42,0.3 -0.57,-0.1 -0.34,-1.05 -1.01,-1.03 -0.22,-0.29 -0.24,-0.81 -0.69,-0.93 -0.6,-0.14 -0.58,-0.94 -1.08,-1.14 l -0.04,0 z",
                        "department-90" : "m 72.33,13.48 c -0.55,0.23 -0.49,0.97 -0.95,1.33 -0.63,0.8 -1.51,1.36 -1.95,2.3 -0.77,0.99 -0.8,2.48 -0.08,3.5 -0.03,0.67 0.48,1.24 0.41,1.93 -0.01,0.83 -0.07,1.76 0.62,2.36 0.29,0.29 0.48,0.66 0.1,0.97 -0.14,0.38 -0.57,0.43 -0.76,0.72 -0.05,0.5 0.53,0.78 0.56,1.29 0.18,0.47 0.52,0.85 0.75,1.28 0.26,0.15 0.87,0.53 0.4,0.81 -0.7,0.47 -0.05,1.72 0.76,1.5 0.78,0.02 1.57,-0.19 2.27,-0.46 0.8,0.18 1.42,0.82 1.46,1.64 0.04,0.86 1.41,0.54 1.43,1.42 0.01,0.47 0.26,1.11 -0.01,1.5 -0.5,0.35 -0.45,-0.64 -0.86,-0.74 -0.5,-0.2 -0.94,0.42 -0.64,0.85 0.2,0.34 -0.18,0.93 0.34,1.04 0.43,0.61 0.84,1.44 0.71,2.19 -0.36,0.5 0.42,0.64 0.75,0.45 0.83,-0.18 1.47,-0.8 2.26,-1.07 0.62,-0.6 -0.22,-1.42 -0.38,-2.05 -0.12,-0.36 -0.45,-1.06 0.17,-1.13 0.42,-0.08 0.81,-0.3 1.15,-0.48 0.96,0.2 1.82,0.91 2.87,0.71 1.1,-0.11 2.47,-0.62 2.45,-1.94 0.17,-1 -0.69,-1.63 -1.42,-2.13 -0.16,-0.46 -0.02,-1.09 -0.52,-1.4 -0.45,-0.55 -0.43,-1.71 -1.38,-1.73 -0.72,-0.12 -1.46,0.05 -1.95,0.59 -0.4,0.24 -0.3,-0.53 -0.6,-0.62 -0.31,-0.79 -0.34,-1.73 0.1,-2.47 0.16,-0.36 0.01,-1.1 0.63,-0.98 0.41,0.01 0.38,-0.37 0.4,-0.64 0.61,-1 -0.15,-2.14 -0.3,-3.13 0.23,-0.47 0.38,-1.05 -0.1,-1.44 -0.8,-1.1 -2.3,-1.18 -3.29,-2.06 -0.38,-0.36 -0.84,-0.58 -1.34,-0.6 -0.84,-0.67 -2.13,-0.38 -2.92,-1.15 -0.45,-0.63 -0.74,-1.4 -0.95,-2.13 -0.05,-0.04 -0.12,-0.05 -0.18,-0.04 z"
                    }
                }
            }
        }
    );

    return Mapael;

}));