{ lib, ... }:

lib.makeIncludes
{
  complete = [
    "tools"
    "tools.bookmarks"
    "tools.bqf"
    "tools.coverage"
    "tools.db"
    "tools.debugging"
    "tools.mini"
    "tools.noice"
    "tools.snacks"
    "tools.testing"
  ];
}
