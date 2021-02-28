FILENAME != "-" {
    dirs[d] = $0;
    d++;
}

FILENAME == "-" {
    skip = 0;
    for (dir in dirs)
        if (index("#" $0, "#" dirs[dir] "/")) {
            skip = 1;
            break;
        }
    if (!skip) {
        print $0;
    }
}