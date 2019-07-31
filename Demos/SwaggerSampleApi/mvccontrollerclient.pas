unit mvccontrollerclient;

interface


uses
    IPPeerClient
  , REST.Client
  , REST.Authenticator.OAuth
  , REST.Types
  , MVCFramework
  , MVCFramework.Commons
  ;


(*
Title: Swagger Petstore
Description: This is a sample server Petstore server.  You can find out more about Swagger at [http://swagger.io](http://swagger.io) or on [irc.freenode.net, #swagger](http://swagger.io/irc/).  For this sample, you can use the api key `special-key` to test the authorization filters.
License: Apache 2.0
*)

type
  TApiResponse = class
    [MVCFormat('int32')]
    code : integer;

    &type : string;

    message : string;

  end;

  TCategory = class
    [MVCFormat('int64')]
    id : int64;

    name : string;

  end;

  TOrder = class
    [MVCFormat('int64')]
    id : int64;

    [MVCFormat('int64')]
    petId : int64;

    [MVCFormat('int32')]
    quantity : integer;

    [MVCFormat('date-time')]
    shipDate : string;

    [MVCDoc('Order Status')]
    status : string;

    complete : boolean;

  end;

  TPet = class
    [MVCFormat('int64')]
    id : int64;

    category : TCategory;

    name : string;

    photoUrls : array of string;

    tags : array of TTag;

    [MVCDoc('pet status in the store')]
    status : string;

  end;

  TTag = class
    [MVCFormat('int64')]
    id : int64;

    name : string;

  end;

  TUser = class
    [MVCFormat('int64')]
    id : int64;

    username : string;

    firstName : string;

    lastName : string;

    email : string;

    password : string;

    phone : string;

    [MVCDoc('User Status')]
    [MVCFormat('int32')]
    userStatus : integer;

  end;

  [MVCPath('/v2')]
  TMyMVCControllerClient = class(TObject)
    RESTClient : TRESTClient;

    RESTRequest : TRESTRequest;

    RESTResponse : TRESTResponse;

    [MVCDoc('')]
    [MVCPath('/pet')]
    [MVCHTTPMethod([httppost])]
    procedure AddPet(Body: TPet);

    [MVCDoc('')]
    [MVCPath('/pet')]
    [MVCHTTPMethod([httpput])]
    procedure UpdatePet(Body: TPet);

    [MVCDoc('Multiple status values can be provided with comma separated strings')]
    [MVCPath('/pet/findByStatus')]
    [MVCHTTPMethod([httpget])]
    procedure FindPetsByStatus(Status: array of string);

    [MVCDoc('Multiple tags can be provided with comma separated strings. Use tag1, tag2, tag3 for testing.')]
    [MVCPath('/pet/findByTags')]
    [MVCHTTPMethod([httpget])]
    procedure FindPetsByTags(Tags: array of string);

    [MVCDoc('Returns a single pet')]
    [MVCPath('/pet/{petId}')]
    [MVCHTTPMethod([httpget])]
    procedure GetPetById(PetId: Integer);

    [MVCDoc('')]
    [MVCPath('/pet/{petId}')]
    [MVCHTTPMethod([httppost])]
    procedure UpdatePetWithForm(PetId: Integer; Name: String; Status: String);

    [MVCDoc('')]
    [MVCPath('/pet/{petId}')]
    [MVCHTTPMethod([httpdelete])]
    procedure DeletePet(Api_key: String; PetId: Integer);

    [MVCDoc('')]
    [MVCPath('/pet/{petId}/uploadImage')]
    [MVCHTTPMethod([httppost])]
    procedure UploadFile(PetId: Integer; AdditionalMetadata: String; File: err File);

    [MVCDoc('Returns a map of status codes to quantities')]
    [MVCPath('/store/inventory')]
    [MVCHTTPMethod([httpget])]
    procedure GetInventory;

    [MVCDoc('')]
    [MVCPath('/store/order')]
    [MVCHTTPMethod([httppost])]
    procedure PlaceOrder(Body: TOrder);

    [MVCDoc('For valid response try integer IDs with value >= 1 and <= 10. Other values will generated exceptions')]
    [MVCPath('/store/order/{orderId}')]
    [MVCHTTPMethod([httpget])]
    procedure GetOrderById(OrderId: Integer);

    [MVCDoc('For valid response try integer IDs with positive integer value. Negative or non-integer values will generate API errors')]
    [MVCPath('/store/order/{orderId}')]
    [MVCHTTPMethod([httpdelete])]
    procedure DeleteOrder(OrderId: Integer);

    [MVCDoc('This can only be done by the logged in user.')]
    [MVCPath('/user')]
    [MVCHTTPMethod([httppost])]
    procedure CreateUser(Body: TUser);

    [MVCDoc('')]
    [MVCPath('/user/createWithArray')]
    [MVCHTTPMethod([httppost])]
    procedure CreateUsersWithArrayInput(Body: array of TUser);

    [MVCDoc('')]
    [MVCPath('/user/createWithList')]
    [MVCHTTPMethod([httppost])]
    procedure CreateUsersWithListInput(Body: array of TUser);

    [MVCDoc('')]
    [MVCPath('/user/login')]
    [MVCHTTPMethod([httpget])]
    procedure LoginUser(Username: String; Password: String);

    [MVCDoc('')]
    [MVCPath('/user/logout')]
    [MVCHTTPMethod([httpget])]
    procedure LogoutUser;

    [MVCDoc('')]
    [MVCPath('/user/{username}')]
    [MVCHTTPMethod([httpget])]
    procedure GetUserByName(Username: String);

    [MVCDoc('This can only be done by the logged in user.')]
    [MVCPath('/user/{username}')]
    [MVCHTTPMethod([httpput])]
    procedure UpdateUser(Username: String; Body: TUser);

    [MVCDoc('This can only be done by the logged in user.')]
    [MVCPath('/user/{username}')]
    [MVCHTTPMethod([httpdelete])]
    procedure DeleteUser(Username: String);

  end;


implementation


uses
    Swag.Doc
  ;



procedure TMyMVCControllerClient.AddPet(Body: TPet);
begin

end;

procedure TMyMVCControllerClient.UpdatePet(Body: TPet);
begin

end;

procedure TMyMVCControllerClient.FindPetsByStatus(Status: array of string);
begin

end;

procedure TMyMVCControllerClient.FindPetsByTags(Tags: array of string);
begin

end;

procedure TMyMVCControllerClient.GetPetById(PetId: Integer);
begin

end;

procedure TMyMVCControllerClient.UpdatePetWithForm(PetId: Integer; Name: String; Status: String);
begin

end;

procedure TMyMVCControllerClient.DeletePet(Api_key: String; PetId: Integer);
begin

end;

procedure TMyMVCControllerClient.UploadFile(PetId: Integer; AdditionalMetadata: String; &File: err File);
begin

end;

procedure TMyMVCControllerClient.GetInventory;
begin

end;

procedure TMyMVCControllerClient.PlaceOrder(Body: TOrder);
begin

end;

procedure TMyMVCControllerClient.GetOrderById(OrderId: Integer);
begin

end;

procedure TMyMVCControllerClient.DeleteOrder(OrderId: Integer);
begin

end;

procedure TMyMVCControllerClient.CreateUser(Body: TUser);
begin

end;

procedure TMyMVCControllerClient.CreateUsersWithArrayInput(Body: array of TUser);
begin

end;

procedure TMyMVCControllerClient.CreateUsersWithListInput(Body: array of TUser);
begin

end;

procedure TMyMVCControllerClient.LoginUser(Username: String; Password: String);
begin

end;

procedure TMyMVCControllerClient.LogoutUser;
begin

end;

procedure TMyMVCControllerClient.GetUserByName(Username: String);
begin

end;

procedure TMyMVCControllerClient.UpdateUser(Username: String; Body: TUser);
begin

end;

procedure TMyMVCControllerClient.DeleteUser(Username: String);
begin

end;

end.
