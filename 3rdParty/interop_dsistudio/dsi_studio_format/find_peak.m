function p = find_peak2(odf,odf_faces,dim)
is_peak = odf;
odf_faces = odf_faces + 1 - (odf_faces > length(odf))*length(odf);
%[a, b] = size(odf_faces);
%odf_faces1 = zeros(1,1,b);
%odf_faces2 = odf_faces1;
%odf_faces3 = odf_faces1;

%odf_faces1(1,1,1:1280)=odf_faces(1,:);
%odf_faces1=repmat(odf_faces1,[dim(1) dim(2) 1]);

%odf_faces2(1,1,1:1280)=odf_faces(2,:);
%odf_faces2=repmat(odf_faces2,[dim(1) dim(2) 1]);

%odf_faces3(1,1,1:1280)=odf_faces(3,:);
%odf_faces3=repmat(odf_faces3,[dim(1) dim(2) 1]);

x1=odf(:,:,odf_faces(2,:)) >= odf(:,:,odf_faces(1,:)) | odf(:,:,odf_faces(3,:)) >= odf(:,:,odf_faces(1,:));
x2=odf(:,:,odf_faces(1,:)) >= odf(:,:,odf_faces(2,:)) | odf(:,:,odf_faces(3,:)) >= odf(:,:,odf_faces(2,:));
x3=odf(:,:,odf_faces(1,:)) >= odf(:,:,odf_faces(3,:)) | odf(:,:,odf_faces(2,:)) >= odf(:,:,odf_faces(3,:));

for i=1:dim(1)
    for j=1:dim(2)
        is_peak(i,j,odf_faces(1,x1(i,j,:))) = 0;
        is_peak(i,j,odf_faces(2,x2(i,j,:))) = 0;
        is_peak(i,j,odf_faces(3,x3(i,j,:))) = 0;
    end
end

%{
is_peak(odf_faces1(odf(:,:,odf_faces(2,:)) >= odf(:,:,odf_faces(1,:)) | odf(:,:,odf_faces(3,:)) >= odf(:,:,odf_faces(1,:)))) = 0;
is_peak(odf_faces2(odf(:,:,odf_faces(1,:)) >= odf(:,:,odf_faces(2,:)) | odf(:,:,odf_faces(3,:)) >= odf(:,:,odf_faces(2,:)))) = 0;
is_peak(odf_faces3(odf(:,:,odf_faces(1,:)) >= odf(:,:,odf_faces(3,:)) | odf(:,:,odf_faces(2,:)) >= odf(:,:,odf_faces(3,:)))) = 0;
%}
[values,ordering] = sort(-is_peak,3);

p=cell(dim(1),dim(2));
for x=1:dim(1)
    for y=1:dim(2)
        p{x,y}=ordering(x,y,(values(x,y,:)<0));
    end
end

%p = ordering(values < 0);
end
