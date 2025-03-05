using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
    public class Role_of_User
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }
        [Required]
        public int user_id { get; set; }
        [Required]
        public int role_id { get; set; }
        [ForeignKey("user_id")]
        public User user { get; set; }
        [ForeignKey("role_id")]
        public Role role { get; set; }
    }
}