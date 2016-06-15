<?php
include './akhet-php-client/AkhetClient.php';

$akhet = new \AkhetClient\AkhetClient("akhet","akhetdemouser","akhetdemopass","http");

?><!DOCTYPE html>
<html>
 <head>
   <title>Akhet Demo</title>
 </head>
 <body>
   <?php
   try {
     switch($_REQUEST['cmd']){
       case 'wait':
        $token = $_REQUEST['token'];
        $instance_info = $akhet->getInstanceInfo($token);
        $status = $instance_info->status;
        if ($status == 0){
        ?>

       <form method="get" action="/index.php">
         <p>
           Your instance is not ready yet
         </p>
         <input type="hidden" name="cmd" value="wait">
         <input type="hidden" name="token" value="<?php echo $token; ?>">
         <input type="submit" value="Re try">
       </form>

      <?php
        }else{
          $url = "/noVNC/vnc.html?resize=scale&autoconnect=1&host=" . $instance_info->host_name . "&port=" . $instance_info->host_port . "&password=" . $instance_info->instance_password . "&path=" . $instance_info->instance_path . "&encrypt=0";
          ?>
          <p>
               <a href="<?php echo $url; ?>">Connect now!</a>
          </p>
          <?php
        }
        break;
       case 'run':
       ?>

      <form method="get" action="/index.php">
        <input type="hidden" name="cmd" value="wait">
        <?php
         $token = $akhet->createInstance(
            array(
                "image" => $_REQUEST['image'],
                "user" => "akhetdemouser",
                "user_label" => "Akhet Demo User",
            )
          );
        ?>
        <input type="hidden" name="token" value="<?php echo $token; ?>">
        <input type="submit" value="Open">
     </form>

     <?php
        break;
       default:
        ?>
     <table>

     <?php
     foreach($akhet->listImages() as $key => $image){
       if(strpos($key,"akhet/")===0){
         $name = $key . ":" . $image->versions[0];
         ?>

           <tr>
             <th><?php echo $key ?></th>
             <td><a href='index.php?cmd=run&amp;image=<?php echo $name; ?>'><?php echo $name; ?></a></td>
           </tr>

         <?php
       }
     }
     ?>

     </table>
     <?php
       break;
     }
   }
   catch(Exception $e){
     ?>
<p>
    <?php
     echo $e->getMessage();
     ?>
</p>
<p>
     <a href="/index.php">Back to the home</a>
</p>
     <?php
   }
    ?>

 </body>
</html>
