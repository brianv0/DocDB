# Copyright 2001-2005 Eric Vaandering, Lynn Garren, Adam Bryant

#    This file is part of DocDB.

#    DocDB is free software; you can redistribute it and/or modify
#    it under the terms of version 2 of the GNU General Public License 
#    as published by the Free Software Foundation.

#    DocDB is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with DocDB; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

sub DocNotifySignup (%) {
  my %Params     = @_;
  my $DocumentID = $Params{-docid};
  
  print "<div id=\"DocNotifySignup\">\n";
  print "<hr/>\n";
  print $query -> start_multipart_form('POST',$WatchDocument);
  print "<dl>\n";
  print $query -> hidden(-name => 'docid', -default => $DocumentID, -override => 1);

  print "<dt>Username:</dt><dd>\n";
  print $query -> textfield(-name => 'username', -size => 12, -maxlength => 32);
  print "</dd>\n";
  print "<dt>Password:</dt><dd>\n";
  print $query -> password_field(-name => 'password', -size => 12, -maxlength => 32);
  print "</dd>\n";

  print "<p>\n";
  print $query -> submit (-value => "Watch Document");
  print "</p>\n";
  
  print "</dl>\n";
  print $query -> end_multipart_form;
  print "</div>\n";
}



1;
