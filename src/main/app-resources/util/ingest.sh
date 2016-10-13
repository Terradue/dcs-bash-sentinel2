#!/bin/bash

###############################################################################
# Copy the Opensearch entry from the local Sandbox Catalogue to a remote one.
# Globals:
#   WORKFLOW
#   APIKEY
#   HOSTNAME
#   USER
###############################################################################

# Local variables
remote_catalog=catalog.terradue.com
index=melodies-training
base_url="https://${remote_catalog}/${index}"

echo "(1/3) Getting the metadata file from the local Sandbox Catalogue"

# Get the local atom response
xml=/tmp/atom.$$.xml
opensearch-client -m EOP "http://$HOSTNAME/sbws/wps/sen2cor/${WORKFLOW}/results/search" {} > ${xml}

# Compute the identifier of the entry
identifier=$( xmlstarlet sel -N x="http://www.w3.org/2005/Atom" -N y="http://purl.org/dc/elements/1.1/" -t -v "/x:feed/x:entry/y:identifier" ${xml})

echo "(2/3) Setting the new metadata (e.g., enclosure, offering, index)"

# Update the atom values
xmlstarlet ed -L -N x="http://www.w3.org/2005/Atom" -u "/x:feed/x:link[@rel='alternate']/@href" -v "${base_url}/?count=20&amp;format=atom" ${xml}
xmlstarlet ed -L -N x="http://www.w3.org/2005/Atom" -u "/x:feed/x:link[@rel='search']/@href" -v "${base_url}/description" ${xml}
xmlstarlet ed -L -N x="http://www.w3.org/2005/Atom" -u "/x:feed/x:link[@rel='self']/@href" -v "${base_url}/search?count=20&amp;format=atom" ${xml}
xmlstarlet ed -L -N x="http://www.w3.org/2005/Atom" -u "/x:feed/x:entry/x:id" -v "${base_url}/search?format=atom&amp;id=${identifier}" ${xml}
xmlstarlet ed -L -N x="http://www.w3.org/2005/Atom" -u "/x:feed/x:entry/x:link[@rel='enclosure']/@href" -v "https://store.terradue.com/${index}/${USER}/${identifier}" ${xml}
xmlstarlet ed -L -N x="http://www.w3.org/2005/Atom" -u "/x:feed/x:entry/x:link[@rel='self']/@href" -v "${base_url}/search?format=atom&amp;id=${identifier}" ${xml}
xmlstarlet ed -L -N x="http://www.w3.org/2005/Atom" -u "/x:feed/x:entry/x:link[@rel='search']/@href" -v "${base_url}/description" ${xml}
xmlstarlet ed -L -N x="http://www.w3.org/2005/Atom" -N y="http://purl.org/dc/elements/1.1/" -u "/x:feed/x:entry/y:parentIdentifier" -v "${base_url}/description" ${xml}

# Set properly the WMS offering
layer_id="${index}:${USER}-${HOSTNAME}-${identifier}"
xmlstarlet ed -L -N x="http://www.w3.org/2005/Atom" -N y="http://www.opengis.net/owc/1.0" -u "/x:feed/x:entry/y:offering/y:content/@href" -v "https://store.terradue.com/${index}/${USER}/${identifier}" ${xml}

echo "(3/3) Uploading the metadata file to the Data Agency Catalogue"

# Finally upload the entry
curl -u ${USER}:${APIKEY} -XPOST -H "Content-Type: application/atom+xml" -d@${xml} "https://catalog.terradue.com/${index}"

res=$?

if [ ${res} -eq 0 ]; then
  echo ""
  echo "DONE: Ingestion successfully performed !"
else
  echo ""
  echo "Oups, sorry something went wrong. Please verify with your instructor."
fi

exit ${res}
