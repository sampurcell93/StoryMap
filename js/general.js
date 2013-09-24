// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    Number.prototype.monthToString = function() {
      var months;
      months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return months[this.valueOf()] || "Not a valid month";
    };
    Number.prototype.dayToString = function() {
      var days;
      days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      return days[this.valueOf() || "Not a valid day"];
    };
    return Date.prototype.cleanFormat = function() {
      return this.getDate() + "/" + this.getMonth() + "/" + this.getFullYear();
    };
  });

}).call(this);
