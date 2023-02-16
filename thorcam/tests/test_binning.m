

asm = System.AppDomain.CurrentDomain.GetAssemblies;

% Set the path to the camera library
path = untitled();
splitPath = split(path,'\');
basePath = join(splitPath(1:end-1),'\');
libraryPath = string(join([basePath 'uc480DotNet.dll'], '\'));

if ~any(arrayfun(@(n) strncmpi(char(asm.Get(n-1).FullName), ...
            'uc480DotNet', length('uc480DotNet')), 1:asm.Length))
    NET.addAssembly(libraryPath);
end

%   Create camera object handle
cam = uc480.Camera;