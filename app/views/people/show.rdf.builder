xml.instruct!
xml.rdf(:RDF,
"xmlns:rdf"  => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
"xmlns:foaf" => "http://xmlns.com/foaf/0.1/",
"xmlns:rdfs" =>"http://www.w3.org/2000/01/rdf-schema#") do

  xml.foaf(:Person) do
    xml.foaf(:name, @person.firstname + ' ' + @person.lastname)
  end

end