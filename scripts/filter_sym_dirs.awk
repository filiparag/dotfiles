FILENAME != "-" {
    dirs[d] = $0;
    d++;
}

FILENAME == "-" {
    for (dir in dirs)
        if ($0 == dirs[dir])
            print $0;
}