function number_to_english(num) {
    var ones = [
        "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", 
        "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", 
        "seventeen", "eighteen", "nineteen"
    ];
    
    var tens = [
        "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"
    ];
    
    if (num < 20) {
        return ones[num];
    }
    
    var t = floor(num / 10);
    var o = num mod 10;
    
    if (o == 0) {
        return tens[t];
    }
    
    return tens[t] + "-" + ones[o];
}

function number_to_funny_english(num) {
    var ones = [
        "hero", "juan", "tooth", "tree", "fork", "hive", "sicks", "even", "ate", "neigh", 
        "tent", "elephant", "lucky", "unlucky", "very-unlucky", "quarter-o'clock", 
        "sick-teen", "severing-teen", "hating-teen", "neighing-teen"
    ];
    
    var tens = [
        "", "", "plenty", "thirsty", "farty", "nifty", "sexy", "heavenly", "achey", "naughty"
    ];
    
    if (num < 20) {
        return ones[num];
    }
    
    var t = floor(num / 10);
    var o = num mod 10;
    
    if (o == 0) {
        return tens[t];
    }
    
    return tens[t] + "-" + ones[o];
}