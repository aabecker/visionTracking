% extracts the center (cc,cr) and radius of the largest blob
function [cc, cr, radius, flag] = extract_umbrella(centroids, cc_tmp, cr_tmp)
  radius = 10;
  dist_get = zeros(size(centroids,1),1);
  for i = 1:size(centroids,1)
      dist_get(i) = sqrt((centroids(i,1) - cc_tmp)^2 + (centroids(i,2) - cr_tmp)^2);
  end
  I = find(dist_get == min(dist_get));
  cc = centroids(I(1),1);
  cr = centroids(I(1),2);
  flag = 1;
  return