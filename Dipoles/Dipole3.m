classdef Dipole3 < handle & matlab.mixin.Copyable
    
    properties
        % starting direction = z-unit vector
        % (u,v,w)
        DirectionVector = [0;0;1];

        % starting position = origin
        % (x,y,z)
        PositionVector = [0;0;0];

        % another z-unit vector used for rotations
        % (only stored as a property for clarity)
        ZUnit = [0;0;1];
    end
    
    properties (Dependent = true)

        Midpoint

        Magnitude

        % spherical coordinates
        % azimuth, CCW rotation about z-axis relative to positive x-axis
        Alpha
        % zenith, tilt from positive z-axis
        Beta

        % coords for vector position ("start point")
        X
        Y
        Z

        % coords for vector direction
        % (these are what we use to find alpha,beta)
        U
        V
        W
    end

    methods
        
        % Beta = theta, Alpha = phi
        function obj = Dipole3(Alpha,Beta)
            obj.Beta = Beta;
            obj.Alpha = Alpha;
        end

        function delete(obj)
            delete(obj);
        end

        function Alpha = get.Alpha(obj)
            % orientation of the projection of the dipole into the x-y plane
            % (relative to the azimuth reference direction: positive x-axis)
            Alpha = atan2d(obj.V,obj.U);

%              if obj.V == 0
%                  Alpha = 0;
%              end
%              
%              % we only want positive values, so add 180
%              % -> equivalent to using the other half-vector to compute alpha
%              if Alpha < 0
%                  Alpha = 180 + Alpha;
%              end
        end

        function Beta = get.Beta(obj)
            % inclination of the dipole 
            % (relative to the zenith: positive z-axis)
            Beta = acosd(obj.W/obj.Magnitude);
        end

        function set.Alpha(obj,val)
            % if we want to only change alpha, we have to reset both alpha and beta
            BetaRotMat = BuildRotationMatrix('Y',obj.Beta);
            AlphaRotMat = BuildRotationMatrix('Z',val);
            obj.DirectionVector = AlphaRotMat*BetaRotMat*obj.ZUnit;
        end

        function set.Beta(obj,val)
            BetaRotMat = BuildRotationMatrix('Y',val);
            AlphaRotMat = BuildRotationMatrix('Z',obj.Alpha);
            obj.DirectionVector = AlphaRotMat*BetaRotMat*obj.ZUnit;
        end

        function Magnitude = get.Magnitude(obj)
            Magnitude = sqrt(obj.U^2+obj.V^2+obj.W^2);
        end

        function X = get.X(obj)
            X = obj.PositionVector(1,1);
        end

        function Y = get.Y(obj)
            Y = obj.PositionVector(2,1);
        end

        function Z = get.Z(obj)
            Z = obj.PositionVector(3,1);
        end

        function U = get.U(obj)
            U = obj.DirectionVector(1,1);
        end

        function V = get.V(obj)
            V = obj.DirectionVector(2,1);
        end

        function W = get.W(obj)
            W = obj.DirectionVector(3,1);
        end

        function Midpoint = get.Midpoint(obj)
            Midpoint = [(obj.X+obj.U)/2;(obj.Y+obj.V)/2;(obj.Z+obj.W)/2];
        end
        
        function RotateDipole(obj,RotationAxis,Theta)
            RotationMatrix = BuildRotationMatrix(RotationAxis,Theta);
            % rotates a dipole or set of dipoles by angle Theta (degrees) about axis RotationAxis (either 'X', 'Y', or 'Z')
%             for i = 1:length(obj)
%                 obj(i).DirectionVector = obj(i).RotateVector(obj(i).DirectionVector,RotationAxis,Theta);
%             end
            for i = 1:length(obj)
                obj(i).DirectionVector = RotationMatrix*obj(i).DirectionVector;
            end            
        end

%         function VectorOut = RotateVector(obj,VectorIn,RotationAxis,Theta)
%             % Inputs:
%             %   VectorIn, column vector to rotate. Ex: [X;Y;Z]
%             %   RotationAxis, char vector specifying rotation axis (either 'X', 'Y', or 'Z')
%             %   Theta, angle (in degrees) by which to rotate around selected axis
% 
%             RotationMatrix = BuildRotationMatrix(RotationAxis,Theta);
%             VectorOut = RotationMatrix*VectorIn;
%         end

        function SetPolarCoordinates(obj,alpha,beta,phi,theta)
            % RotationMatrix gives dipole coordinates in the cartesian (x-y-z) reference frame 
            %   (when used to premultiply a z-unit column vector)
            % beta is inclination relative to zenith (positive z-axis)
            % alpha is the orientation of the dipole after projection onto the x-y plane, 
            %   relative to the azimuth reference direction (positive x-axis)
            RotationMatrix = [cosd(beta)*cosd(alpha) -sind(alpha) sind(beta)*cosd(alpha);
                              cosd(beta)*sind(alpha) cosd(alpha) sind(beta)*sind(alpha);
                              -sind(beta) 0 cosd(beta)];
            % WobbleMatrix sets the position of each dipole within a "wobble cone"
            % theta is dipole zenith in the cone reference frame
            % phi is dipole azimuth in the cone reference frame
            % when theta and phi are both 0°, WobbleMatrix is a z-unit column vector (i.e. [0;0;1])
            WobbleMatrix = [sind(theta)*cosd(phi);sind(theta)*sind(phi);cosd(theta)];
            obj.DirectionVector = RotationMatrix*WobbleMatrix;
        end

        function RotationMatrix = BuildAlphaBetaRotationMatrix(alpha,beta)
            RotationMatrix = [cosd(beta)*cosd(alpha) -sind(alpha) sind(beta)*cosd(alpha);
                              cosd(beta)*sind(alpha) cosd(alpha) sind(beta)*sind(alpha);
                              -sind(beta) 0 cosd(beta)];
        end


        function RotationMatrix = BuildRotationMatrix(RotationAxis,Theta)
            switch RotationAxis
                case 'X'
                    RotationMatrix = [1 0 0;0 cosd(Theta) -sind(Theta);0 sind(Theta) cosd(Theta)];
                case 'Y'
                    RotationMatrix = [cosd(Theta) 0 sind(Theta);0 1 0;-sind(Theta) 0 cosd(Theta)];
                case 'Z'
                    RotationMatrix = [cosd(Theta) -sind(Theta) 0;sind(Theta) cosd(Theta) 0;0 0 1];
            end
        end        
        
        function ExcitationProbability = FindExcitationProbability(obj,omega)
            % Alpha and beta are azimuthal and polar angles of the fluorophores
            % Omega is azimuthal angle of E-Field
            ExcitationProbability = (sind(obj.Beta).^2)*(cosd(obj.Alpha-omega).^2);
        end

        function EmissionPhotonCount = AttemptExcitation(obj,omega,ExcitationPhotonCount)
            EmissionPhotonCount = 0;
            for DipoleIdx = 1:length(obj)
                ExcitationProbability = obj(DipoleIdx).FindExcitationProbability(omega);
                for i = 1:ExcitationPhotonCount
                    % get random number in (0,1) from uniform distribution
                    checkProbability = rand();
                    if checkProbability < ExcitationProbability
                        EmissionPhotonCount = EmissionPhotonCount+1;
                    end
                end
            end

        end




    end

end